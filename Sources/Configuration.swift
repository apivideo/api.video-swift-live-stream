//
//  Configuration.swift
//  ApiVideoLiveStream
//

import Foundation

class Resolution{
    var width: Int
    var height: Int

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
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

public struct AudioConfig {
    let bitrate: Int
    let sampleRate: Int
    let stereo: Bool
    
    public init(bitrate: Int, sampleRate: Int, stereo: Bool) {
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.stereo = stereo
    }
}

public struct VideoConfig {
    let bitrate: Int
    let resolution: Resolutions
    let fps: Int
    
    public init(bitrate: Int, resolution: Resolutions, fps: Int) {
        self.bitrate = bitrate
        self.resolution = resolution
        self.fps = fps
    }
}
