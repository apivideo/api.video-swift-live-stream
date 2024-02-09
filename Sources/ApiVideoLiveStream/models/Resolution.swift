import Foundation

/// Resolution of the video
public enum Resolution {
    // 16:9
    /// 426x240
    case RESOLUTION_16_9_240P
    /// 640x360: nHD
    case RESOLUTION_16_9_360P
    /// 854x480: FWVGA
    case RESOLUTION_16_9_480P
    /// 1280x720: WXGA
    case RESOLUTION_16_9_720P
    /// 1920x1080: FHD
    case RESOLUTION_16_9_1080P

    // 4:3
    /// 320x240: QVGA
    case RESOLUTION_4_3_240P
    /// 640x480: VGA
    case RESOLUTION_4_3_480P
    /// 800x600: SVGA
    case RESOLUTION_4_3_600P
    /// 1024x768: XGA
    case RESOLUTION_4_3_768P
    /// 1440x1080
    case RESOLUTION_4_3_1080P
}

// MARK: RawRepresentable

extension Resolution: RawRepresentable {
    public typealias RawValue = CGSize

    public init?(rawValue: RawValue) {
        let widerWidth = max(rawValue.width, rawValue.height)
        let widerHeight = min(rawValue.width, rawValue.height)
        switch (widerWidth, widerHeight) {
        case (426, 240):
            self = .RESOLUTION_16_9_240P

        case (640, 360):
            self = .RESOLUTION_16_9_360P

        case (854, 480):
            self = .RESOLUTION_16_9_480P

        case (1_280, 720):
            self = .RESOLUTION_16_9_720P

        case (1_920, 1_080):
            self = .RESOLUTION_16_9_1080P

        case (320, 240):
            self = .RESOLUTION_4_3_240P

        case (640, 480):
            self = .RESOLUTION_4_3_480P

        case (800, 600):
            self = .RESOLUTION_4_3_600P

        case (1_024, 768):
            self = .RESOLUTION_4_3_768P

        case (1_440, 1_080):
            self = .RESOLUTION_4_3_1080P

        default: return nil
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .RESOLUTION_16_9_240P:
            return CGSize(width: 426, height: 240)

        case .RESOLUTION_16_9_360P:
            return CGSize(width: 640, height: 360)

        case .RESOLUTION_16_9_480P:
            return CGSize(width: 854, height: 480)

        case .RESOLUTION_16_9_720P:
            return CGSize(width: 1_280, height: 720)

        case .RESOLUTION_16_9_1080P:
            return CGSize(width: 1_920, height: 1_080)

        case .RESOLUTION_4_3_240P:
            return CGSize(width: 320, height: 240)

        case .RESOLUTION_4_3_480P:
            return CGSize(width: 640, height: 480)

        case .RESOLUTION_4_3_600P:
            return CGSize(width: 800, height: 600)

        case .RESOLUTION_4_3_768P:
            return CGSize(width: 1_024, height: 768)

        case .RESOLUTION_4_3_1080P:
            return CGSize(width: 1_440, height: 1_080)
        }
    }

}
