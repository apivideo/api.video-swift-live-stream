import CoreGraphics
import Foundation
import Network

public struct AudioConfig {
    public let bitrate: Int

    /// Creates an audio configuration object
    /// - Parameters:
    ///   - bitrate: The audio bitrate in bits per second
    public init(bitrate: Int = 128_000) {
        self.bitrate = bitrate
    }
}

public struct VideoConfig {
    public let bitrate: Int
    public let resolution: CGSize
    public let fps: Float64
    public let gopDuration: TimeInterval

    /// Creates a video configuration object with explicit video bitrate and CGSize resolution
    /// - Parameters:
    ///   - bitrate: The video bitrate in bits per second
    ///   - resolution: The video resolution
    ///   - fps: The video framerate
    ///   - gopDuration: The time interval between two key frames
    public init(
        bitrate: Int,
        resolution: CGSize = CGSize(width: 1_280, height: 720),
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.bitrate = bitrate
        self.resolution = resolution
        self.fps = fps
        self.gopDuration = gopDuration
    }

    /// Creates a video configuration object with default video bitrate and CGSize resolution
    /// - Parameters:
    ///   - resolution: The video resolution
    ///   - fps: The video framerate
    ///   - gopDuration: The time interval between two key frames
    public init(
        resolution: CGSize = CGSize(width: 1_280, height: 720),
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.bitrate = VideoConfig.getDefaultBitrate(resolution)
        self.resolution = resolution
        self.fps = fps
        self.gopDuration = gopDuration
    }

    /// Creates a video configuration object with default video bitrate
    /// - Parameters:
    ///   - resolution: The video resolution
    ///   - fps: The video framerate
    ///   - gopDuration: The time interval between two key frames
    public init(
        resolution: Resolution,
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.init(resolution: resolution.rawValue, fps: fps, gopDuration: gopDuration)
    }

    /// Creates a video configuration object with explicit video bitrate
    /// - Parameters:
    ///   - bitrate: The video bitrate in bits per second
    ///   - resolution: The video resolution
    ///   - fps: The video framerate
    ///   - gopDuration: The time interval between two key frames
    public init(
        bitrate: Int,
        resolution: Resolution,
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.init(bitrate: bitrate, resolution: resolution.rawValue, fps: fps, gopDuration: gopDuration)
    }

    static func getDefaultBitrate(_ size: CGSize) -> Int {
        let numOfPixels = size.width * size.height
        switch numOfPixels {
        case 0 ... 102_240: return 800_000 // for 4/3 and 16/9 240p
        case 102_241 ... 230_400: return 1_000_000 // for 16/9 360p
        case 230_401 ... 409_920: return 1_300_000 // for 4/3 and 16/9 480p
        case 409_921 ... 921_600: return 2_000_000 // for 4/3 600p, 4/3 768p and 16/9 720p
        default: return 3_000_000 // for 16/9 1080p
        }
    }
}

enum ConfigurationError: Error {
    case invalidParameter(String)
}
