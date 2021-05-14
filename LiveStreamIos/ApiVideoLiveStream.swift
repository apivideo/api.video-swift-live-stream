//
//  ApiVideoLiveStream.swift
//  LiveStreamIos
//
//  Created by Romain Petit on 29/04/2021.
//
import HaishinKit
import AVFoundation
import Foundation
import VideoToolbox

class Resolution{
    var width: Int
    var height: Int
    var videoBitrate: Int
    var profilLevel: String
    
    init(width: Int, height: Int, videoBitrate: Int, _ profilLevel: String) {
        self.width = width
        self.height = height
        self.videoBitrate = videoBitrate
        self.profilLevel = profilLevel
    }
}

public class ApiVideoLiveStream{
    public enum Orientation : Int {
        case landscape = 0
        case portrait = 1
    }
    
    public enum Resolutions {
        case RESOLUTION_240
        case RESOLUTION_360
        case RESOLUTION_480
        case RESOLUTION_720
        case RESOLUTION_1080
        case RESOLUTION_2160
        
        var instance: Resolution{
            switch self {
            case .RESOLUTION_240:
                return Resolution(width: 352, height: 240, videoBitrate: 400*1000, kVTProfileLevel_H264_Baseline_3_1 as String)
            case .RESOLUTION_360:
                return Resolution(width: 480, height: 360, videoBitrate: 800 * 1000, kVTProfileLevel_H264_Baseline_3_1 as String)
            case .RESOLUTION_480:
                return Resolution(width: 858, height: 480, videoBitrate: 1200 * 1000, kVTProfileLevel_H264_Baseline_3_1 as String)
            case .RESOLUTION_720:
                return Resolution(width: 1280, height: 720, videoBitrate: 2250 * 1000, kVTProfileLevel_H264_Baseline_3_1 as String)
            case .RESOLUTION_1080:
                return Resolution(width: 1920, height: 1080, videoBitrate: 4500 * 1000, kVTProfileLevel_H264_High_4_0 as String)
            case .RESOLUTION_2160:
                return Resolution(width: 3860, height: 2160, videoBitrate: 16000 * 1000, kVTProfileLevel_H264_High_AutoLevel as String)
            }
        }
    }
    
    private var ratioConstraint: NSLayoutConstraint?
    private var mthkView: MTHKView?
    
    private var livestreamkey: String?
    private var rtmpServerUrl: String?
    
    private var rtmpStream: RTMPStream
    private var rtmpConnection = RTMPConnection()
    private var currentPosition: AVCaptureDevice.Position = .back
    private var retryCount: Int = 0
    private static let maxRetryCount: Int = 5
    
    
    public var videoResolution: Resolutions = Resolutions.RESOLUTION_720{
        didSet{
            updateRatioConstraint()
        }
    }
    
    public var videoFps: Double = 30.0{
        didSet{
            setCaptureSettings()
        }
    }
    
    public var videoBitrate: Int? = nil {
        didSet{
        }
    }
    
    public var videoCamera: AVCaptureDevice.Position = .back {
        didSet{
            prepareCamera()
        }
    }
    public var videoOrientation: Orientation = .landscape {
        didSet{
            updateRatioConstraint()
        }
    }
    
    public var audioMuted: Bool = false{
        didSet{
            setAudioSettings()
        }
    }
    public var audioBitrate: Int = 128 * 1000{
        didSet{
            setAudioSettings()
        }
    }
    

    public init(view: UIView?){
        rtmpStream = RTMPStream(connection: rtmpConnection)
        
        NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async {
            if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                print("orientation \(orientation.rawValue)")
                self.rtmpStream.orientation = orientation
            }
        }
        
        rtmpStream.setZoomFactor(CGFloat(0), ramping: true, withRate: 5.0)
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print("======== Audio Flux Error ==========")
            print(error.description)
        }
        
        prepareCamera()
        setCaptureSettings()
        setAudioSettings()
        
        if (view != nil) {
            mthkView = MTHKView(frame: view!.bounds)
            mthkView!.translatesAutoresizingMaskIntoConstraints = false
            mthkView!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            mthkView!.attachStream(rtmpStream)
            view!.addSubview(mthkView!)

            updateRatioConstraint()
            let maxWidth = mthkView!.widthAnchor.constraint(lessThanOrEqualTo: view!.widthAnchor)
            let maxHeight = mthkView!.heightAnchor.constraint(lessThanOrEqualTo: view!.heightAnchor)
            let width = mthkView!.widthAnchor.constraint(equalTo: view!.widthAnchor)
            let height = mthkView!.heightAnchor.constraint(equalTo: view!.heightAnchor)
            let centerX = mthkView!.centerXAnchor.constraint(equalTo: view!.centerXAnchor)
            let centerY = mthkView!.centerYAnchor.constraint(equalTo: view!.centerYAnchor)

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
            let newRatio = videoOrientation == .landscape ? CGFloat(videoResolution.instance.width) / CGFloat(videoResolution.instance.height) : CGFloat(videoResolution.instance.height) / CGFloat(videoResolution.instance.width)
            ratioConstraint = mthkView!.widthAnchor.constraint(equalTo: mthkView!.heightAnchor, multiplier: newRatio)
            ratioConstraint?.isActive = true
            mthkView?.layoutIfNeeded()
        }
    }
    
    private func prepareCamera(){
        rtmpStream.captureSettings[.isVideoMirrored] = videoCamera == .front
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: videoCamera)) { error in
                print("======== Camera Flux Error ==========")
                print(error.description)
        }
    }

    
    public func startLiveStreamFlux(liveStreamKey: String, rtmpServerUrl: String?) -> Void{
        self.livestreamkey = liveStreamKey
        self.rtmpServerUrl = rtmpServerUrl
        
        setVideoSettings()

        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.connect(rtmpServerUrl ?? "rtmp://broadcast.api.video/s")
    }
    
    public func stopLiveStreamFlux() -> Void{
        rtmpConnection.close()
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }
    
    private func setCaptureSettings(){
        rtmpStream.captureSettings = [
            .fps: videoFps,
            .continuousAutofocus: true,
            .continuousExposure: true,
            .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
    }
    
    private func setAudioSettings(){
        rtmpStream.audioSettings = [
            .muted: audioMuted,
            .bitrate: audioBitrate,
        ]
    }
    
    private func setVideoSettings(){
        rtmpStream.videoSettings = [
            .width: videoOrientation == .landscape ? videoResolution.instance.width : videoResolution.instance.height,
            .height: videoOrientation == .landscape ? videoResolution.instance.height : videoResolution.instance.width,
            .profileLevel: videoResolution.instance.profilLevel,
            .bitrate: videoBitrate ?? videoResolution.instance.videoBitrate,
            .maxKeyFrameIntervalDuration: 0,
        ]
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
            rtmpStream.publish(self.livestreamkey!)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            guard retryCount <= ApiVideoLiveStream.maxRetryCount else {
                return
            }
            Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
            rtmpConnection.connect(self.rtmpServerUrl ?? "rtmp://broadcast.api.video/s")
            retryCount += 1
        default:
            break
        }
    }
    
    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        let e = Event.from(notification)
        print("rtmpErrorHandler: \(e)")
        DispatchQueue.main.async {
            self.rtmpConnection.connect(self.rtmpServerUrl ?? "rtmp://broadcast.api.video/s")
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
