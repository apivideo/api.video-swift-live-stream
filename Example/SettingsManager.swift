//
//  SettingsManager.swift
//  Example
//


import Foundation
import ApiVideoLiveStream

class SettingsManager{
    public static var videoBitrate: Int = 2 * 1024 * 1024
    public static var resolution: Resolutions = Resolutions.RESOLUTION_720
    public static var framerate: Int = 30
    public static var audioBitrate: Int = 32 * 1000
    public static var endPoint: String = "rtmp://broadcast.api.video/s"
    public static var streamKey: String = ""
    
    
    public static func getVideoConfig() -> VideoConfig{
        let video = VideoConfig(bitrate: videoBitrate , resolution: resolution, fps: framerate)
        return video
    }
    
    public static func getAudioConfig() -> AudioConfig{
        let audio = AudioConfig(bitrate: audioBitrate)
        return audio
    }
}
