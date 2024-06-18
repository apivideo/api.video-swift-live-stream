import AVFoundation
import Foundation
import HaishinKit
import VideoToolbox
#if !os(macOS)
import UIKit
#endif

class IOLiveStream: LiveStreamProtocol {
    private let ioStream: IOStream

    private(set) var isAudioConfigured = false
    private(set) var isVideoConfigured = false

    /// The delegate of the ApiVideoLiveStream
    weak var delegate: ApiVideoLiveStreamDelegate?

    ///  Getter and Setter for an AudioConfig
    var audioConfig: AudioConfig {
        get {
            AudioConfig(bitrate: self.ioStream.audioSettings.bitRate)
        }
        set {
            self.prepareAudio(audioConfig: newValue)
        }
    }

    /// Getter and Setter for a VideoConfig
    var videoConfig: VideoConfig {
        get {
            VideoConfig(
                bitrate: Int(self.ioStream.videoSettings.bitRate),
                resolution: CGSize(
                    width: Int(self.ioStream.videoSettings.videoSize.width),
                    height: Int(self.ioStream.videoSettings.videoSize.height)
                ),
                fps: self.ioStream.frameRate,
                gopDuration: TimeInterval(self.ioStream.videoSettings.maxKeyFrameIntervalDuration)
            )
        }
        set {
            self.prepareVideo(videoConfig: newValue)
        }
    }

    /// Getter and Setter for the Bitrate number for the video
    var videoBitrate: Int {
        get {
            self.ioStream.videoSettings.bitRate
        }
        set(newValue) {
            self.ioStream.videoSettings.bitRate = newValue
        }
    }

    private var lastCamera: AVCaptureDevice?

    /// Camera position
    var cameraPosition: AVCaptureDevice.Position {
        get {
            guard let position = ioStream.videoCapture(for: 0)?.device?.position else {
                return AVCaptureDevice.Position.unspecified
            }
            return position
        }
        set(newValue) {
            self.attachCamera(newValue)
        }
    }

    /// Camera device
    var camera: AVCaptureDevice? {
        get {
            self.ioStream.videoCapture(for: 0)?.device
        }
        set(newValue) {
            self.attachCamera(newValue)
        }
    }

    /// Mutes or unmutes audio capture.
    var isMuted: Bool {
        get {
            !self.ioStream.audioMixerSettings.isMuted
        }
        set(newValue) {
            self.ioStream.audioMixerSettings.isMuted = !newValue
        }
    }

    #if os(iOS)
    /// Zoom on the video capture
    var zoomRatio: CGFloat {
        get {
            guard let device = ioStream.videoCapture(for: 0)?.device else {
                return 1.0
            }
            return device.videoZoomFactor
        }
        set(newValue) {
            guard let device = ioStream.videoCapture(for: 0)?.device, newValue >= 1,
                  newValue < device.activeFormat.videoMaxZoomFactor else
            {
                return
            }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = newValue
                device.unlockForConfiguration()
            } catch let error as NSError {
                print("Error while locking device for zoom ramp: \(error)")
            }
        }
    }
    #endif

    var isConnected: Bool {
        fatalError("Not implemented")
    }

    /// Creates a new ApiVideoLiveStream object without a preview
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's initial AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's initial VideoConfig
    ///   - initialCamera: The ApiVideoLiveStream's initial camera device
    init(
        ioStream: IOStream,
        initialAudioConfig: AudioConfig? = AudioConfig(),
        initialVideoConfig: VideoConfig? = VideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    ) throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()

        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        #endif

        self.ioStream = ioStream

        // Force default resolution because HK default resolution is not supported (480x272)
        self.ioStream.videoSettings = VideoCodecSettings(videoSize: .init(width: 1_280, height: 720))

        if let initialCamera = initialCamera {
            self.attachCamera(initialCamera)
        }
        if let initialVideoConfig = initialVideoConfig {
            self.prepareVideo(videoConfig: initialVideoConfig)
        }

        self.attachAudio()
        if let initialAudioConfig = initialAudioConfig {
            self.prepareAudio(audioConfig: initialAudioConfig)
        }
    }

    private func attachCamera(_ cameraPosition: AVCaptureDevice.Position) {
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
        self.attachCamera(camera)
    }

    private func attachCamera(_ camera: AVCaptureDevice?) {
        self.lastCamera = camera

        self.ioStream.attachCamera(camera) { videoCaptureUnit, error in
            if let error {
                print("======== Camera error ==========")
                print(error)
                self.delegate?.videoError(error)
                return
            }

            if let camera {
                videoCaptureUnit?.isVideoMirrored = camera.position == .front
            }
            #if os(iOS)
            // videoCaptureUnit.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode
            //   .auto // Add latency to video
            #endif

            guard let device = videoCaptureUnit?.device else {
                return
            }
            self.ioStream.lockQueue.async {
                do {
                    try device.lockForConfiguration()
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for exposure and focus: \(error)")
                }
            }
        }
    }

    private func prepareVideo(videoConfig: VideoConfig) {
        self.ioStream.frameRate = videoConfig.fps
        self.ioStream.sessionPreset = AVCaptureSession.Preset.high

        let resolution = videoConfig.resolution
        let width = self.ioStream.videoOrientation
            .isLandscape ? max(resolution.width, resolution.height) : min(resolution.width, resolution.height)
        let height = self.ioStream.videoOrientation
            .isLandscape ? min(resolution.width, resolution.height) : max(resolution.width, resolution.height)

        self.ioStream.videoSettings = VideoCodecSettings(
            videoSize: CGSize(width: width, height: height),
            bitRate: videoConfig.bitrate,
            profileLevel: kVTProfileLevel_H264_Baseline_5_2 as String,
            maxKeyFrameIntervalDuration: Int32(videoConfig.gopDuration)
        )

        self.isVideoConfigured = true
    }

    private func attachAudio() {
        self.ioStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { _, error in
            if let error {
                print("======== Audio error ==========")
                print(error)
                self.delegate?.audioError(error)
            }
        }
    }

    func prepareAudio(audioConfig: AudioConfig) {
        self.ioStream.audioSettings.bitRate = audioConfig.bitrate

        self.isAudioConfigured = true
    }

    func attachPreview(_ view: IOStreamView) {
        view.attachStream(self.ioStream)
    }

    func startPreview() {
        guard let lastCamera = lastCamera else {
            print("No camera has been set")
            return
        }
        self.attachCamera(lastCamera)
        self.attachAudio()
    }

    func stopPreview() {
        self.ioStream.attachCamera(nil)
        self.ioStream.attachAudio(nil)
    }

    func startStreaming(streamKey _: String, url _: String) throws {
        fatalError("Not implemented")
    }

    func stopStreaming() {
        fatalError("Not implemented")
    }

    #if os(iOS)
    func orientationDidChange() {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }

        self.ioStream.lockQueue.async {
            self.ioStream.videoOrientation = orientation

            let currentVideoSize = self.ioStream.videoSettings.videoSize
            var newVideoSize: CGSize
            if self.ioStream.videoOrientation.isLandscape {
                newVideoSize = CGSize(
                    width: max(currentVideoSize.width, currentVideoSize.height),
                    height: min(currentVideoSize.width, currentVideoSize.height)
                )
            } else {
                newVideoSize = CGSize(
                    width: min(currentVideoSize.width, currentVideoSize.height),
                    height: max(currentVideoSize.width, currentVideoSize.height)
                )
            }
            self.ioStream.videoSettings.videoSize = newVideoSize
        }
    }
    #endif
}
