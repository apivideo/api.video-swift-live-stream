import ApiVideoLiveStream
import Foundation

enum SettingsManager {
    // MARK: Endpoint

    static var rtmpUrl: String {
        UserDefaults.standard.string(forKey: "RtmpUrl") ?? "rtmp://broadcast.api.video/s/"
    }

    static var streamKey: String {
        UserDefaults.standard.string(forKey: "StreamKey") ?? ""
    }

    // MARK: Video

    private static var videoBitrate: Int {
        UserDefaults.standard.integer(forKey: "VideoBitrate")
    }

    private static var resolution: Resolution {
        do {
            return try UserDefaults.standard.string(forKey: "Resolution")?.toResolution() ?? Resolution
                .RESOLUTION_16_9_720P
        } catch {
            fatalError("Can't get resolution from user defaults")
        }
    }

    private static var framerate: Float64 {
        UserDefaults.standard.double(forKey: "Framerate")
    }

    public static var videoConfig: VideoConfig {
        VideoConfig(bitrate: videoBitrate * 1_000, resolution: resolution, fps: framerate)
    }

    // MARK: Audio

    private static var audioBitrate: Int {
        UserDefaults.standard.integer(forKey: "AudioBitrate")
    }

    public static var audioConfig: AudioConfig {
        AudioConfig(bitrate: audioBitrate)
    }
}

// MARK: Convert functions

extension String {
    func toResolution() throws -> Resolution {
        let resolutionArray = self.components(separatedBy: "x")
        guard let width = Int(resolutionArray[0]) else {
            throw ParameterError.Invalid("Width is invalid")
        }
        guard let height = Int(resolutionArray[1]) else {
            throw ParameterError.Invalid("Height is invalid")
        }
        let resolution = Resolution(rawValue: CGSize(width: width, height: height))
        if let resolution {
            return resolution
        } else {
            throw ParameterError.Invalid("Resolution is invalid for \(width)x\(height)")
        }
    }
}

extension Resolution {
    func toString() -> String {
        "\(rawValue.width)x\(rawValue.height)"
    }
}

public enum ParameterError: Error {
    case Invalid(String)
}
