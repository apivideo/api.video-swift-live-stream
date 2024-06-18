import AVFoundation
import Foundation

extension AVCaptureVideoOrientation {
    var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
}
