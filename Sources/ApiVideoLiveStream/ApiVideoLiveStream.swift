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
    ///  Can't be updated
    public var audioConfig: AudioConfig {
        get {
            AudioConfig(bitrate: rtmpStream.audioSettings[.bitrate] as! Int)
        }
        set {
            prepareAudio(audioConfig: newValue)
        }
    }

    /// Getter and Setter for a VideoConfig
    /// Can't be updated
    public var videoConfig: VideoConfig {
        get {
            try! VideoConfig(bitrate: Int(rtmpStream.videoSettings[.bitrate] as! UInt32), resolution: Resolution.getResolution(width: Int(rtmpStream.videoSettings[.width] as! Int32), height: Int(rtmpStream.videoSettings[.height] as! Int32)), fps: rtmpStream.frameRate)
        }
        set {
            prepareVideo(videoConfig: newValue)
        }
    }

    /// Getter and Setter for the Bitrate number for the video
    public var videoBitrate: Int {
        get {
            rtmpStream.videoSettings[.bitrate] as! Int
        }
        set(newValue) {
            rtmpStream.videoSettings[.bitrate] = newValue
        }
    }

    /// Camera position
    public var cameraPosition: AVCaptureDevice.Position = .back {
        didSet {
            attachCamera()
        }
    }

    /// Audio mute or not.
    public var isMuted: Bool {
        get {
            rtmpStream.hasAudio
        }
        set(newValue) {
            rtmpStream.hasAudio = newValue
        }
    }

    #if os(iOS)
    public var zoomRatio: CGFloat {
        get {
            guard let device = rtmpStream.videoCapture(for: 0)?.device else {
                return 1.0
            }
            return device.videoZoomFactor
        }
        set(newValue) {
            guard let device = rtmpStream.videoCapture(for: 0)?.device, 1 <= newValue && newValue < device.activeFormat.videoMaxZoomFactor else {
                return
            }
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: newValue, withRate: 5.0)
                device.unlockForConfiguration()
            } catch let error as NSError {
                print("while locking device for ramp: \(error)")
            }
        }
    }
    #endif

    /// init a new ApiVideoLiveStream without preview
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    public init(initialAudioConfig: AudioConfig?, initialVideoConfig: VideoConfig?) throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()

        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        #endif

        rtmpStream = RTMPStream(connection: rtmpConnection)
        // Force default resolution because HK default resolution is not supported (480x272)
        rtmpStream.videoSettings[.width] = 1280
        rtmpStream.videoSettings[.height] = 720

        #if os(iOS)
        if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
            rtmpStream.videoOrientation = orientation
        }

        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)),
                name: UIDevice.orientationDidChangeNotification, object: nil)
        #endif

        attachCamera()
        if let initialVideoConfig = initialVideoConfig {
            prepareVideo(videoConfig: initialVideoConfig)
        }
        attachAudio()
        if let initialAudioConfig = initialAudioConfig {
            prepareAudio(audioConfig: initialAudioConfig)
        }

        #if !os(macOS)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        #endif

        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }

    #if !os(macOS)
    /// init a new ApiVideoLiveStream with an UIView
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    ///   - preview: UiView to display the preview of camera
    public convenience init(initialAudioConfig: AudioConfig?, initialVideoConfig: VideoConfig?, preview: UIView) throws {
        try self.init(initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig)

        let mthkView = MTHKView(frame: preview.bounds)
        mthkView.translatesAutoresizingMaskIntoConstraints = false
        mthkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        mthkView.attachStream(rtmpStream)

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
            maxWidth, maxHeight, width, height, centerX, centerY,
        ])
    }
    #endif

    /// init a new ApiVideoLiveStream with a NetStreamDrawable
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    ///   - preview: UiView to display the preview of camera
    public convenience init(initialAudioConfig: AudioConfig?, initialVideoConfig: VideoConfig?, preview: NetStreamDrawable) throws {
        try self.init(initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig)
        preview.attachStream(rtmpStream)
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
        rtmpStream.videoCapture(for: 0)?.isVideoMirrored = cameraPosition == .front
        rtmpStream.lockQueue.sync {
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
            rtmpStream.attachCamera(camera) { error in
                print("======== Camera error ==========")
                print(error)
                self.delegate?.videoError(error)
            }
        }
    }

    private func prepareVideo(videoConfig: VideoConfig) {
        rtmpStream.lockQueue.sync {
            // rtmpStream.videoCapture(for: 0)?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto // Add latency to video
            rtmpStream.frameRate = videoConfig.fps
            rtmpStream.sessionPreset = AVCaptureSession.Preset.high
            guard let device = rtmpStream.videoCapture(for: 0)?.device else {
                return
            }
            do {
                try device.lockForConfiguration()
                device.exposureMode = .continuousAutoExposure
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for exposure and focus: \(error)")
            }
        }
        rtmpStream.videoSettings = [
            .width: rtmpStream.videoOrientation.isLandscape ? videoConfig.resolution.size.width : videoConfig.resolution.size.height,
            .height: rtmpStream.videoOrientation.isLandscape ? videoConfig.resolution.size.height : videoConfig.resolution.size.width,
            .profileLevel: kVTProfileLevel_H264_Baseline_5_2,
            .bitrate: videoConfig.bitrate,
            .maxKeyFrameIntervalDuration: 1,
        ]

        isVideoConfigured = true
    }

    private func attachAudio() {
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print("======== Audio error ==========")
            print(error)
            self.delegate?.audioError(error)
        }
    }

    private func prepareAudio(audioConfig: AudioConfig) {
        rtmpStream.audioSettings = [
            .bitrate: audioConfig.bitrate,
        ]

        isAudioConfigured = true
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
        if !isAudioConfigured || !isVideoConfigured {
            throw LiveStreamError.IllegalArgumentError("Missing audio and/or video configuration")
        }

        self.streamKey = streamKey
        self.url = url

        rtmpStream.lockQueue.sync {
            rtmpConnection.connect(url)
        }
    }

    /// Stop your livestream
    /// - Returns: Void
    public func stopStreaming() {
        let isConnected = rtmpConnection.connected
        rtmpConnection.close()
        if isConnected {
            delegate?.onDisconnect()
        }
    }

    public func startPreview() {
        attachCamera()
        attachAudio()
    }

    public func stopPreview() {
        rtmpStream.attachCamera(nil)
        rtmpStream.attachAudio(nil)
    }

    @objc private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            delegate?.onConnectionSuccess()
            rtmpStream.publish(streamKey)
        case RTMPConnection.Code.connectFailed.rawValue:
            delegate?.onConnectionFailed(code)
        case RTMPConnection.Code.connectClosed.rawValue:
            delegate?.onDisconnect()
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
        rtmpStream.videoOrientation = orientation

        rtmpStream.videoSettings = [
            .width: rtmpStream.videoOrientation.isLandscape ? videoConfig.resolution.size.width : videoConfig.resolution.size.height,
            .height: rtmpStream.videoOrientation.isLandscape ? videoConfig.resolution.size.height : videoConfig.resolution.size.width,
        ]
    }
    #endif

    #if !os(macOS)
    @objc
    private func didEnterBackground(_: Notification) {
        stopStreaming()
    }
    #endif
}

public protocol ApiVideoLiveStreamDelegate: AnyObject {
    /// Called when the connection to the rtmp server is successful
    func onConnectionSuccess()

    /// Called when the connection to the rtmp server failed
    func onConnectionFailed(_ code: String)

    /// Called when the connection to the rtmp server is closed
    func onDisconnect()

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
