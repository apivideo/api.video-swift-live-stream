//
//  SettingsManager.swift
//  Example
//
//  Created by Romain Petit on 21/01/2022.
//

import Foundation
import ApiVideoLiveStream

class SettingsManager{
    public static var videoBitrate: Int = 2 * 1024 * 1024
    public static var resolution: Resolutions = Resolutions.RESOLUTION_720
    public static var framerate: Int = 30
    public static var audioBitrate: Int = 32 * 1000
    public static var endPoint: String = "rtmp://192.168.1.48:1935/s"
    public static var streamKey: String = "77143677-1898-4fc4-bf21-e5e0f6a7f1de"
    
    
    public static func getVideoConfig() -> VideoConfig{
        let video = VideoConfig(bitrate: videoBitrate , resolution: resolution, fps: framerate)
        return video
    }
    
    public static func getAudioConfig() -> AudioConfig{
        let audio = AudioConfig(bitrate: audioBitrate)
        return audio
    }
}
