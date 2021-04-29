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

public class ApiVideoLiveStream{
    public init(){}
    private var livestreamkey: String?
    private var rtmpStream: RTMPStream!
    private var rtmpConnection = RTMPConnection()
    private var currentPosition: AVCaptureDevice.Position = .back
    private var retryCount: Int = 0
    private static let maxRetryCount: Int = 5
    
    public func startLiveStreamFlux(liveStreamKey: String, captureQuality: String, streamQuality: String, fps: Float64) -> Void{
        self.livestreamkey = liveStreamKey
        
        rtmpConnection.connect("rtmp://broadcast.api.video/s")
        rtmpStream = RTMPStream(connection: rtmpConnection)
        
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
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: .back)) { error in
            print("======== Camera Flux Error ==========")
            print(error.description)
        }
        
        
        setCaptureVideo(quality: captureQuality, fps: fps)
        setStreamVideoQuality(quality: streamQuality)
        
        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }
    

    private func setCaptureVideo(quality: String, fps: Float64){
        switch quality {
        case "240p":
            // 352 * 240
            rtmpStream.captureSettings = [
                .fps: fps,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
        case "360p":
            // 480 * 360
            rtmpStream.captureSettings = [
                .fps: fps,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
            
        case "480p":
            // 858 * 480
            rtmpStream.captureSettings = [
                .fps: fps,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
        case "720p":
            // 1280 * 720
            rtmpStream.captureSettings = [
                .fps: fps,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
        case "1080p":
            // 1920 * 1080
            rtmpStream.captureSettings = [
                .fps: fps,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
        case "2160p":
            // 3860 * 2160
            rtmpStream.captureSettings = [
                .fps: fps,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
        default:
            rtmpStream.captureSettings = [
                .fps: 24,
                .sessionPreset: AVCaptureSession.Preset.inputPriority,
                .continuousAutofocus: true,
                .continuousExposure: true,
                .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
            ]
            
            rtmpStream.audioSettings = [
                .muted: false, // mute audio
                .bitrate: 128 * 1000,
            ]
        }
    }
    
    private func setStreamVideoQuality(quality: String){
        switch quality {
        case "240p":
            // 352 * 240
            rtmpStream.videoSettings = [
                .width: 352,
                .height: 240,
                .bitrate: 400 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2,// key frame / sec
            ]
            
        case "360p":
            // 480 * 360
            rtmpStream.videoSettings = [
                .width: 480,
                .height: 360,
                .bitrate: 800 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2, // key frame / sec
            ]
            
        case "480p":
            // 858 * 480
            rtmpStream.videoSettings = [
                .width: 858,
                .height: 480,
                .bitrate: 1200 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2, // key frame / sec
            ]
        case "720p":
            // 1280 * 720
            rtmpStream.videoSettings = [
                .width: 1280,
                .height: 720,
                .bitrate: 2250 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2, // key frame / sec
            ]
        case "1080p":
            // 1920 * 1080
            rtmpStream.videoSettings = [
                .width: 1920,
                .height: 1080,
                .profileLevel: kVTProfileLevel_H264_High_4_0,
                .bitrate: 4500 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2, // key frame / sec
            ]
        case "2160p":
            // 3860 * 2160
            rtmpStream.videoSettings = [
                .width: 3860,
                .height: 2160,
                .profileLevel: kVTProfileLevel_H264_High_AutoLevel,
                .bitrate: 160000 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2, // key frame / sec
            ]
        default:
            rtmpStream.videoSettings = [
                .width: 480,
                .height: 360,
                .bitrate: 400 * 1000, // video output bitrate
                .maxKeyFrameIntervalDuration: 2, // key frame / sec
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
            rtmpStream!.publish(self.livestreamkey!)
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
    
//    @objc
//    private func on(_ notification: Notification) {
//        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication) else {
//            return
//        }
//        rtmpStream.orientation = orientation
//    }
    

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


