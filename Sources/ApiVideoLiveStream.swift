//
//  ApiVideoLiveStream.swift
//
import HaishinKit
import AVFoundation
import Foundation
import VideoToolbox

public class ApiVideoLiveStream{
    private var ratioConstraint: NSLayoutConstraint?
    private var mthkView: MTHKView?
    private var streamKey: String = ""
    private var url: String = ""
    private var rtmpStream: RTMPStream
    private var rtmpConnection = RTMPConnection()
    
    public var onConnectionSuccess: (() -> ())? = nil
    public var onConnectionFailed: ((String) -> ())? = nil
    public var onDisconnect: (() -> ())? = nil
    
    
    ///  Set a new AudioConfig
    ///  Can't be updated
    public var audioConfig: AudioConfig {
        didSet{
            prepareAudio()
        }
    }
    
    /// Set a new VideoConfig
    /// Can't be updated
    public var videoConfig: VideoConfig {
        didSet{
            prepareVideo()
        }
    }
    
    /// Bitrate number for the video
    /// Can be updated
    public var videoBitrate: Int? = nil {
        didSet{
            rtmpStream.videoSettings[.bitrate] = videoBitrate
        }
    }
    
    /// Camera position
    /// Can be updated
    public var camera: AVCaptureDevice.Position = .back {
        didSet{
            attachCamera()
        }
    }
    
    /// Audio mute or not.
    /// Can be updated
    public var isMuted: Bool = false {
        didSet{
            rtmpStream.audioSettings[.muted] = isMuted
        }
    }
    
    
    /// init ApiVideoLiveStream
    /// - Parameters:
    ///   - initialAudioConfig: AudioConfig
    ///   - initialVideoConfig: VideoConfig
    ///   - preview: UiView to display the preview of camera
    public init(initialAudioConfig: AudioConfig, initialVideoConfig: VideoConfig, preview: UIView?) throws {
        let session = AVAudioSession.sharedInstance()
        
        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        if #available(iOS 10.0, *) {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        } else {
            session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [
                AVAudioSession.CategoryOptions.allowBluetooth,
                AVAudioSession.CategoryOptions.defaultToSpeaker]
            )
            try session.setMode(.default)
        }
        try session.setActive(true)
        
        
        self.audioConfig = initialAudioConfig
        self.videoConfig = initialVideoConfig
        
        rtmpStream = RTMPStream(connection: rtmpConnection)
        NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        DispatchQueue.main.async {
            if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                print("orientation \(orientation.rawValue)")
                self.rtmpStream.orientation = orientation
            }
        }

        attachCamera()
        prepareVideo()
        attachAudio()
        prepareAudio()
        
        if (preview != nil) {
            mthkView = MTHKView(frame: preview!.bounds)
            mthkView!.translatesAutoresizingMaskIntoConstraints = false
            mthkView!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            mthkView!.attachStream(rtmpStream)
            preview!.addSubview(mthkView!)
            
            updateRatioConstraint()
            let maxWidth = mthkView!.widthAnchor.constraint(lessThanOrEqualTo: preview!.widthAnchor)
            let maxHeight = mthkView!.heightAnchor.constraint(lessThanOrEqualTo: preview!.heightAnchor)
            let width = mthkView!.widthAnchor.constraint(equalTo: preview!.widthAnchor)
            let height = mthkView!.heightAnchor.constraint(equalTo: preview!.heightAnchor)
            let centerX = mthkView!.centerXAnchor.constraint(equalTo: preview!.centerXAnchor)
            let centerY = mthkView!.centerYAnchor.constraint(equalTo: preview!.centerYAnchor)
            
            width.priority = .defaultHigh
            height.priority = .defaultHigh
            
            NSLayoutConstraint.activate([
                maxWidth, maxHeight, width, height, centerX, centerY
            ])
        }
    }
    
    private func updateRatioConstraint() {
        if (mthkView != nil) {
            ratioConstraint?.isActive = false
            let newRatio = self.rtmpStream.orientation.isLandscape ? CGFloat(videoConfig.resolution.instance.width) / CGFloat(videoConfig.resolution.instance.height) : CGFloat(videoConfig.resolution.instance.height) / CGFloat(videoConfig.resolution.instance.width)
            ratioConstraint = mthkView!.widthAnchor.constraint(equalTo: mthkView!.heightAnchor, multiplier: newRatio)
            ratioConstraint?.isActive = true
            mthkView?.layoutIfNeeded()
        }
    }
    
    private func attachCamera() {
        rtmpStream.captureSettings[.isVideoMirrored] = camera == .front
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: camera)) { error in
            print("======== Camera error ==========")
            print(error.description)
        }
    }
    
    private func prepareVideo() {
        rtmpStream.captureSettings = [
            .fps: videoConfig.fps,
            .continuousAutofocus: true,
            .continuousExposure: true,
            .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
        rtmpStream.videoSettings = [
            .width: self.rtmpStream.orientation.isLandscape ? videoConfig.resolution.instance.width : videoConfig.resolution.instance.height,
            .height: self.rtmpStream.orientation.isLandscape ? videoConfig.resolution.instance.height : videoConfig.resolution.instance.width,
            .profileLevel: kVTProfileLevel_H264_High_AutoLevel,
            .bitrate: videoConfig.bitrate,
            .maxKeyFrameIntervalDuration: 1,
        ]
    }
    
    private func attachAudio() {
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print("======== Audio error ==========")
            print(error.description)
        }
    }
    
    private func prepareAudio() {
        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(audioConfig.sampleRate))
        } catch {
        }
        rtmpStream.audioSettings = [
            .bitrate: audioConfig.bitrate,
        ]
    }
    
    /// Function to start your livestream
    /// - Parameters:
    ///   - streamKey: String value
    ///   - url: String value, by default : rtmp://broadcast.api.video/s
    /// - Returns: Void
    public func startStreaming(streamKey: String, url: String = "rtmp://broadcast.api.video/s") -> Void{
        self.streamKey = streamKey
        self.url = url
                
        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        
        rtmpConnection.connect(url)
    }
    
    /// Function to stop livestream
    /// - Returns: Void
    public func stopStreaming() -> Void{
        if (self.onDisconnect != nil) {
            self.onDisconnect!()
        }
        rtmpConnection.close()
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            if (self.onConnectionSuccess != nil) {
                self.onConnectionSuccess!()
            }
            rtmpStream.publish(self.streamKey)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            if (self.onConnectionFailed != nil) {
                self.onConnectionFailed!(code)
            }
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
    
    @objc
    private func on(_ notification: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        rtmpStream.orientation = orientation
    }
}

extension AVCaptureVideoOrientation {
    var isLandscape: Bool { return self == .landscapeLeft || self == .landscapeRight }
}
