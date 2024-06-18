import AVFoundation
import Foundation
import HaishinKit

protocol LiveStreamProtocol {
    var audioConfig: AudioConfig { get set }
    var videoConfig: VideoConfig { get set }
    var videoBitrate: Int { get set }
    var cameraPosition: AVCaptureDevice.Position { get set }
    var camera: AVCaptureDevice? { get set }
    var isMuted: Bool { get set }
    var isConnected: Bool { get }
    #if os(iOS)
    var zoomRatio: CGFloat { get set }
    func orientationDidChange()
    #endif

    func attachPreview(_ view: IOStreamView)

    func startStreaming(streamKey: String, url: String) throws
    func stopStreaming()

    func startPreview()
    func stopPreview()
}
