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
            return try UserDefaults.standard.string(forKey: "Resolution")?.toResolution() ?? Resolution.RESOLUTION_720
        } catch {
            print("Can't get resolution from user defaults")
            return Resolution.RESOLUTION_720
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
        return try Resolution.getResolution(width: width, height: height)
    }
}

extension Resolution {
    func toString() -> String {
        "\(size.width)x\(size.height)"
    }
}

public enum ParameterError: Error {
    case Invalid(String)
}
