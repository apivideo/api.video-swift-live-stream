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
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public class ApiVideoLiveStream{
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
                return Resolution(width: 352, height: 240)
            case .RESOLUTION_360:
                return Resolution(width: 480, height: 360)
            case .RESOLUTION_480:
                return Resolution(width: 858, height: 480)
            case .RESOLUTION_720:
                return Resolution(width: 1280, height: 720)
            case .RESOLUTION_1080:
                return Resolution(width: 1920, height: 1080)
            case .RESOLUTION_2160:
                return Resolution(width: 3860, height: 2160)
            }
        }
    }
    
    private var livestreamkey: String?
    private var rtmpStream: RTMPStream
    private var rtmpConnection = RTMPConnection()
    private var currentPosition: AVCaptureDevice.Position = .back
    private var retryCount: Int = 0
    private static let maxRetryCount: Int = 5
    
    public var videoResolution: Resolutions = Resolutions.RESOLUTION_720{
        didSet{
            print("oldValue Resolution : h =\(oldValue.instance.height) ; w = \(oldValue.instance.width)")
            print("newValue Resolution : h =\(videoResolution.instance.height) ; w = \(videoResolution.instance.width)")
            setStreamVideoQuality(resolution: videoResolution)
        }
    }
    
    public var videoFps: Double = 30.0{
        didSet{
            print("oldValue : fps =\(oldValue)")
            print("newValue : fps =\(videoFps) ; w = \(videoResolution.instance.width)")
            setCaptureVideo(fps: Double(videoFps))
        }
    }
    
    public var videoCamera: AVCaptureDevice.Position = .back {
        didSet{
            print("oldValue videoCamera : \(oldValue.rawValue)")
            print("newValue videoCamera : \(videoCamera.rawValue)")
            prepareCamera()
        }
    }
    
    public var audioMuted: Bool = false{
        didSet{
            print("oldValue muted : \(oldValue)")
            print("newValue muted : \(audioMuted)")
            setCaptureVideo(fps: Double(videoFps))
        }
    }
    

    public init(view: UIView?){
        rtmpStream = RTMPStream(connection: rtmpConnection)
        
        NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async {
            if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                self.rtmpStream.orientation = orientation
            }
        }
        
        rtmpStream.setZoomFactor(CGFloat(0), ramping: true, withRate: 5.0)
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print("======== Audio Flux Error ==========")
            print(error.description)
        }
        
        prepareCamera()
        
        if (view != nil) {
            let hkView = MTHKView(frame: view!.bounds)
            hkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
            hkView.attachStream(rtmpStream)
            view!.addSubview(hkView)
            
            setCaptureVideo(fps: Double(videoFps))
            setStreamVideoQuality(resolution: videoResolution)
//            setStreamVideoQuality(resolution: videoResolution)
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

        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.connect(rtmpServerUrl ?? "rtmp://broadcast.api.video/s")
    }
    
    public func stopLiveStreamFlux() -> Void{
        rtmpConnection.close()
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }
    
    private func setCaptureVideo(fps: Float64){
        rtmpStream.captureSettings = [
            .fps: fps,
            //.sessionPreset: AVCaptureSession.Preset.low,
            .continuousAutofocus: true,
            .continuousExposure: true,
            .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
        
        rtmpStream.audioSettings = [
            .muted: audioMuted, // mute audio
            .bitrate: 128 * 1000,
        ]
    }
    
    private func setStreamVideoQuality(resolution: Resolutions){
        switch resolution {
        case .RESOLUTION_240:
            // 352 * 240
            rtmpStream.videoSettings = [
                .width: Resolutions.RESOLUTION_240.instance.width,
                .height: Resolutions.RESOLUTION_240.instance.height,
                .bitrate: 400 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 0,// key frame / sec
            ]
            
        case .RESOLUTION_360:
            // 480 * 360
            rtmpStream.videoSettings = [
                .width: Resolutions.RESOLUTION_360.instance.width,
                .height: Resolutions.RESOLUTION_360.instance.height,
                .bitrate: 800 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 0, // key frame / sec
            ]
            
        case .RESOLUTION_480:
            // 858 * 480
            rtmpStream.videoSettings = [
                .width: Resolutions.RESOLUTION_480.instance.width,
                .height: Resolutions.RESOLUTION_480.instance.height,
                .bitrate: 1200 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 0, // key frame / sec
            ]
        case .RESOLUTION_720:
            // 1280 * 720
            rtmpStream.videoSettings = [
                .width: Resolutions.RESOLUTION_720.instance.width,
                .height: Resolutions.RESOLUTION_720.instance.height,
                .bitrate: 2250 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 0, // key frame / sec
            ]
        case .RESOLUTION_1080:
            // 1920 * 1080
            rtmpStream.videoSettings = [
                .width: Resolutions.RESOLUTION_1080.instance.width,
                .height: Resolutions.RESOLUTION_1080.instance.height,
                .profileLevel: kVTProfileLevel_H264_High_4_0,
                .bitrate: 4500 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 0, // key frame / sec
            ]
        case .RESOLUTION_2160:
            // 3860 * 2160
            rtmpStream.videoSettings = [
                .width: Resolutions.RESOLUTION_2160.instance.width,
                .height: Resolutions.RESOLUTION_2160.instance.height,
                .profileLevel: kVTProfileLevel_H264_High_AutoLevel,
                .bitrate: 160000 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 0, // key frame / sec
            ]
        }
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
            rtmpConnection.connect("rtmp://broadcast.api.video/s")
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
            self.rtmpConnection.connect("rtmp://broadcast.api.video/s")
        }
    }
    
    @objc
    private func on(_ notification: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        rtmpStream.orientation = orientation
    }
    

    public func upload(filePath: String) -> String {
        let rtmpConnection = RTMPConnection()
        
        let rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
             print(error)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: .back)) { error in
             print(error)
        }

        rtmpConnection.connect("rtmp://localhost/appName/instanceName")
        rtmpStream.publish("streamName")
        return String(rtmpConnection.connected)
    }
}
