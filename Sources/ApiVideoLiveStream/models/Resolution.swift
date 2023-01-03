import Foundation

public enum Resolution {
    case RESOLUTION_240
    case RESOLUTION_360
    case RESOLUTION_480
    case RESOLUTION_720
    case RESOLUTION_1080

    public var size: CGSize {
        switch self {
        case .RESOLUTION_240:
            return CGSize(width: 352, height: 240)

        case .RESOLUTION_360:
            return CGSize(width: 480, height: 360)

        case .RESOLUTION_480:
            return CGSize(width: 858, height: 480)

        case .RESOLUTION_720:
            return CGSize(width: 1280, height: 720)

        case .RESOLUTION_1080:
            return CGSize(width: 1920, height: 1080)
        }
    }

    public static func getResolution(width: Int, height: Int) throws -> Resolution {
        let widerWidth = max(width, height)
        let widerHeight = min(width, height)
        switch (widerWidth, widerHeight) {
        case (352, 240):
            return .RESOLUTION_240

        case (480, 360):
            return .RESOLUTION_360

        case (858, 480):
            return .RESOLUTION_480

        case (1280, 720):
            return .RESOLUTION_720

        case (1920, 1080):
            return .RESOLUTION_1080

        default:
            throw ConfigurationError.invalidParameter("Resolution \(width)x\(height) is not supported")
        }
    }
}

extension CGSize {
    public var resolution: Resolution {
        get throws {
            try Resolution.getResolution(width: Int(width), height: Int(height))
        }
    }
}