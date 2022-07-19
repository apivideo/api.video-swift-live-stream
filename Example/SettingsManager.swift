//
//  SettingsManager.swift
//  Example
//

import ApiVideoLiveStream
import Foundation

class SettingsManager {
    public static var videoBitrate: Int = 2 * 1000 // in Kpbs
    public static var resolution: Resolution = .RESOLUTION_720
    public static var framerate: Int = 30
    public static var audioBitrate: Int = 32 * 1000
    public static var endPoint: String = "rtmp://broadcast.api.video/s"
    public static var streamKey: String = ""

    public static func getVideoConfig() -> VideoConfig {
        let video = VideoConfig(bitrate: videoBitrate * 1000, resolution: resolution, fps: framerate)
        return video
    }

    public static func getAudioConfig() -> AudioConfig {
        let audio = AudioConfig(bitrate: audioBitrate)
        return audio
    }
}
