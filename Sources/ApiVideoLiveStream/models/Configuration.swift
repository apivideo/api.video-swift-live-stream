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
    public let resolution: Resolution
    public let fps: Float64
    public let gopDuration: TimeInterval

    /// Creates a video configuration object with default video bitrate
    /// - Parameters:
    ///   - resolution: The video resolution
    ///   - fps: The video framerate
    ///   - gopDuration: The time interval between two key frames
    public init(
        resolution: Resolution = Resolution.RESOLUTION_720,
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.bitrate = VideoConfig.getDefaultBitrate(resolution: resolution)
        self.resolution = resolution
        self.fps = fps
        self.gopDuration = gopDuration
    }

    /// Creates a video configuration object with explicit video bitrate
    /// - Parameters:
    ///   - bitrate: The video bitrate in bits per second
    ///   - resolution: The video resolution
    ///   - fps: The video framerate
    ///   - gopDuration: The time interval between two key frames
    public init(
        bitrate: Int,
        resolution: Resolution = Resolution.RESOLUTION_720,
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.bitrate = bitrate
        self.resolution = resolution
        self.fps = fps
        self.gopDuration = gopDuration
    }

    static func getDefaultBitrate(resolution: Resolution) -> Int {
        switch resolution {
        case Resolution.RESOLUTION_240: return 800_000
        case Resolution.RESOLUTION_360: return 1_000_000
        case Resolution.RESOLUTION_480: return 1_300_000
        case Resolution.RESOLUTION_720: return 2_000_000
        case Resolution.RESOLUTION_1080: return 3_500_000
        }
    }
}

enum ConfigurationError: Error {
    case invalidParameter(String)
}
