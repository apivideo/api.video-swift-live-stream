import AVFoundation
import Foundation
import HaishinKit
#if !os(macOS)
import UIKit
#endif

class RtmpLiveStream: IOLiveStream {
    private let stream: RTMPStream
    private let connection = RTMPConnection()

    private var streamKey: String = ""
    private var url: String = ""

    override var isConnected: Bool {
        self.connection.connected
    }

    /// Creates a new ApiVideoLiveStream object without a preview
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's initial AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's initial VideoConfig
    ///   - initialCamera: The ApiVideoLiveStream's initial camera device
    init(
        initialAudioConfig: AudioConfig? = AudioConfig(),
        initialVideoConfig: VideoConfig? = VideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    ) throws {
        self.stream = RTMPStream(connection: self.connection)

        try super.init(
            ioStream: self.stream,
            initialAudioConfig: initialAudioConfig,
            initialVideoConfig: initialVideoConfig,
            initialCamera: initialCamera
        )
    }

    deinit {
        connection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        connection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
    }

    /// Start your livestream
    /// - Parameters:
    ///   - streamKey: The key of your live
    ///   - url: The url of your rtmp server, by default it's rtmp://broadcast.api.video/s
    /// - Returns: Void
    override func startStreaming(streamKey: String, url: String = "rtmp://broadcast.api.video/s") throws {
        if streamKey.isEmpty {
            throw LiveStreamError.IllegalArgumentError("Stream key must not be empty")
        }
        if url.isEmpty {
            throw LiveStreamError.IllegalArgumentError("URL must not be empty")
        }
        if !self.isAudioConfigured || !self.isVideoConfigured {
            throw LiveStreamError.IllegalOperationError("Missing audio and/or video configuration")
        }

        self.streamKey = streamKey
        self.url = url

        self.stream.fcPublishName = streamKey

        Task {
            self.connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            self.connection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)

            self.connection.connect(url)
        }
    }

    /// Stop your livestream
    /// - Returns: Void
    override func stopStreaming() {
        let isConnected = isConnected

        Task {
            self.connection.close()
            connection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            connection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)

            if isConnected {
                self.delegate?.disconnection()
            }
        }
    }

    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject,
              let code: String = data["code"] as? String,
              let level: String = data["level"] as? String else
        {
            print("rtmpStatusHandler: failed to parse event: \(e)")
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            self.stream.publish(self.streamKey)

        case RTMPStream.Code.publishStart.rawValue:
            self.delegate?.connectionSuccess()

        case RTMPConnection.Code.connectClosed.rawValue:
            self.delegate?.disconnection()

        default:
            if level == "error" {
                self.delegate?.connectionFailed(code)
            }
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        let e = Event.from(notification)
        print("rtmpErrorHandler: \(e)")
        DispatchQueue.main.async {
            self.connection.connect(self.url)
        }
    }
}
