//
//  ApiVideoLiveStream.swift
//

import AVFoundation
import Foundation
import HaishinKit
#if !os(macOS)
import UIKit
#endif
import VideoToolbox

public class ApiVideoLiveStream {
    private let rtmpStream: RTMPStream
    private let rtmpConnection = RTMPConnection()

    private var streamKey: String = ""
    private var url: String = ""

    private var isAudioConfigured = false
    private var isVideoConfigured = false

    /// The delegate of the ApiVideoLiveStream
    public weak var delegate: ApiVideoLiveStreamDelegate?

    ///  Getter and Setter for an AudioConfig
    // swiftlint:disable force_cast
    public var audioConfig: AudioConfig {
        get {
            AudioConfig(bitrate: self.rtmpStream.audioSettings[.bitrate] as! Int)
        }
        set {
            self.prepareAudio(audioConfig: newValue)
        }
    }

    /// Getter and Setter for a VideoConfig
    // swiftlint:disable force_cast force_try
    public var videoConfig: VideoConfig {
        get {
            try! VideoConfig(
                    bitrate: Int(self.rtmpStream.videoSettings[.bitrate] as! UInt32),
                    resolution: Resolution.getResolution(
                            width: Int(self.rtmpStream.videoSettings[.width] as! Int32),
                            height: Int(self.rtmpStream.videoSettings[.height] as! Int32)
                    ),
                    fps: self.rtmpStream.frameRate
            )
        }
        set {
            self.prepareVideo(videoConfig: newValue)
        }
    }

    /// Getter and Setter for the Bitrate number for the video
    // swiftlint:disable force_cast
    public var videoBitrate: Int {
        get {
            self.rtmpStream.videoSettings[.bitrate] as! Int
        }
        set(newValue) {
            self.rtmpStream.videoSettings[.bitrate] = newValue
        }
    }

    /// Camera position
    public var cameraPosition: AVCaptureDevice.Position = .back {
        didSet {
            self.attachCamera()
        }
    }

    /// Mutes or unmutes audio capture.
    public var isMuted: Bool {
        get {
            self.rtmpStream.hasAudio
        }
        set(newValue) {
            self.rtmpStream.hasAudio = newValue
        }
    }

    #if os(iOS)
    /// Zoom on the video capture
    // swiftlint:disable implicit_return
    public var zoomRatio: CGFloat {
        get {
            guard let device = rtmpStream.videoCapture(for: 0)?.device else {
                return 1.0
            }
            return device.videoZoomFactor
        }
        set(newValue) {
            guard let device = rtmpStream.videoCapture(for: 0)?.device, newValue >= 1,
                  newValue < device.activeFormat.videoMaxZoomFactor
            else {
                return
            }
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: newValue, withRate: 5.0)
                device.unlockForConfiguration()
            } catch let error as NSError {
                print("Error while locking device for zoom ramp: \(error)")
            }
        }
    }
    #endif

    /// init a new ApiVideoLiveStream without preview
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    public init(initialAudioConfig: AudioConfig? = AudioConfig(), initialVideoConfig: VideoConfig? = VideoConfig()) throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()

        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        #endif

        self.rtmpStream = RTMPStream(connection: self.rtmpConnection)
        // Force default resolution because HK default resolution is not supported (480x272)
        self.rtmpStream.videoSettings[.width] = 1_280
        self.rtmpStream.videoSettings[.height] = 720

        #if os(iOS)
        if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
            self.rtmpStream.videoOrientation = orientation
        }

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.orientationDidChange(_:)),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
        )
        #endif

        self.attachCamera()
        if let initialVideoConfig = initialVideoConfig {
            self.prepareVideo(videoConfig: initialVideoConfig)
        }
        self.attachAudio()
        if let initialAudioConfig = initialAudioConfig {
            self.prepareAudio(audioConfig: initialAudioConfig)
        }

        #if !os(macOS)
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.didEnterBackground(_:)),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
        )
        #endif

        self.rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(self.rtmpStatusHandler), observer: self)
        self.rtmpConnection.addEventListener(.ioError, selector: #selector(self.rtmpErrorHandler), observer: self)
    }

    #if !os(macOS)
    /// init a new ApiVideoLiveStream with an UIView
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    ///   - preview: UiView to display the preview of camera
    public convenience init(
            preview: UIView,
            initialAudioConfig: AudioConfig? = AudioConfig(),
            initialVideoConfig: VideoConfig? = VideoConfig()
    ) throws {
        try self.init(initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig)

        let mthkView = MTHKView(frame: preview.bounds)
        mthkView.translatesAutoresizingMaskIntoConstraints = false
        mthkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        mthkView.attachStream(self.rtmpStream)

        preview.addSubview(mthkView)

        let maxWidth = mthkView.widthAnchor.constraint(lessThanOrEqualTo: preview.widthAnchor)
        let maxHeight = mthkView.heightAnchor.constraint(lessThanOrEqualTo: preview.heightAnchor)
        let width = mthkView.widthAnchor.constraint(equalTo: preview.widthAnchor)
        let height = mthkView.heightAnchor.constraint(equalTo: preview.heightAnchor)
        let centerX = mthkView.centerXAnchor.constraint(equalTo: preview.centerXAnchor)
        let centerY = mthkView.centerYAnchor.constraint(equalTo: preview.centerYAnchor)

        width.priority = .defaultHigh
        height.priority = .defaultHigh

        NSLayoutConstraint.activate([
            maxWidth, maxHeight, width, height, centerX, centerY
        ])
    }
    #endif

    /// init a new ApiVideoLiveStream with a NetStreamDrawable
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    ///   - preview: UiView to display the preview of camera
    public convenience init(
            preview: NetStreamDrawable,
            initialAudioConfig: AudioConfig? = AudioConfig(),
            initialVideoConfig: VideoConfig? = VideoConfig()
    ) throws {
        try self.init(initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig)
        preview.attachStream(self.rtmpStream)
    }

    deinit {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        #endif
        #if !os(macOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        #endif
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }

    private func attachCamera() {
        self.rtmpStream.videoCapture(for: 0)?.isVideoMirrored = self.cameraPosition == .front
        self.rtmpStream.lockQueue.sync {
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
            rtmpStream.attachCamera(camera) { error in
                print("======== Camera error ==========")
                print(error)
                self.delegate?.videoError(error)
            }
        }
    }

    private func prepareVideo(videoConfig: VideoConfig) {
        self.rtmpStream.lockQueue.sync {
            // rtmpStream.videoCapture(for: 0)?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto // Add latency to video
            rtmpStream.frameRate = videoConfig.fps
            rtmpStream.sessionPreset = AVCaptureSession.Preset.high
            guard let device = rtmpStream.videoCapture(for: 0)?.device else {
                return
            }
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
        self.rtmpStream.videoSettings = [
            .width: self.rtmpStream.videoOrientation.isLandscape ? videoConfig.resolution.size.width : videoConfig
                    .resolution.size.height,
            .height: self.rtmpStream.videoOrientation.isLandscape ? videoConfig.resolution.size.height : videoConfig
                    .resolution.size.width,
            .profileLevel: kVTProfileLevel_H264_Baseline_5_2,
            .bitrate: videoConfig.bitrate,
            .maxKeyFrameIntervalDuration: 1
        ]

        self.isVideoConfigured = true
    }

    private func attachAudio() {
        self.rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print("======== Audio error ==========")
            print(error)
            self.delegate?.audioError(error)
        }
    }

    private func prepareAudio(audioConfig: AudioConfig) {
        self.rtmpStream.audioSettings = [
            .bitrate: audioConfig.bitrate
        ]

        self.isAudioConfigured = true
    }

    /// Start your livestream
    /// - Parameters:
    ///   - streamKey: The key of your live
    ///   - url: The url of your rtmp server, by default it's rtmp://broadcast.api.video/s
    /// - Returns: Void
    public func startStreaming(streamKey: String, url: String = "rtmp://broadcast.api.video/s") throws {
        if streamKey.isEmpty {
            throw LiveStreamError.IllegalArgumentError("Stream key must not be empty")
        }
        if !self.isAudioConfigured || !self.isVideoConfigured {
            throw LiveStreamError.IllegalArgumentError("Missing audio and/or video configuration")
        }

        self.streamKey = streamKey
        self.url = url

        self.rtmpStream.lockQueue.sync {
            rtmpConnection.connect(url)
        }
    }

    /// Stop your livestream
    /// - Returns: Void
    public func stopStreaming() {
        let isConnected = self.rtmpConnection.connected
        self.rtmpConnection.close()
        if isConnected {
            self.delegate?.disconnection()
        }
    }

    public func startPreview() {
        self.attachCamera()
        self.attachAudio()
    }

    public func stopPreview() {
        self.rtmpStream.attachCamera(nil)
        self.rtmpStream.attachAudio(nil)
    }

    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            self.delegate?.connectionSuccess()
            self.rtmpStream.publish(self.streamKey)

        case RTMPConnection.Code.connectFailed.rawValue:
            self.delegate?.connectionFailed(code)

        case RTMPConnection.Code.connectClosed.rawValue:
            self.delegate?.disconnection()

        default:
            break
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        let e = Event.from(notification)
        print("rtmpErrorHandler: \(e)")
        DispatchQueue.main.async {
            self.rtmpConnection.connect(self.url)
        }
    }

    #if os(iOS)
    @objc
    private func orientationDidChange(_: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        self.rtmpStream.videoOrientation = orientation

        self.rtmpStream.videoSettings = [
            .width: self.rtmpStream.videoOrientation.isLandscape ? self.videoConfig.resolution.size.width : self
                    .videoConfig.resolution.size.height,
            .height: self.rtmpStream.videoOrientation.isLandscape ? self.videoConfig.resolution.size.height : self
                    .videoConfig.resolution.size.width
        ]
    }
    #endif

    #if !os(macOS)
    @objc
    private func didEnterBackground(_: Notification) {
        self.stopStreaming()
    }
    #endif
}

public protocol ApiVideoLiveStreamDelegate: AnyObject {
    /// Called when the connection to the rtmp server is successful
    func connectionSuccess()

    /// Called when the connection to the rtmp server failed
    func connectionFailed(_ code: String)

    /// Called when the connection to the rtmp server is closed
    func disconnection()

    /// Called if an error happened during the audio configuration
    func audioError(_ error: Error)

    /// Called if an error happened during the video configuration
    func videoError(_ error: Error)
}

extension AVCaptureVideoOrientation {
    var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
}

public enum LiveStreamError: Error {
    case IllegalArgumentError(String)
}
