import AVFoundation
import Foundation
import SRTHaishinKit

class SrtLiveStream: IOLiveStream {
    private let stream: SRTStream
    private let connection = SRTConnection()
    private var keyValueObservations: [NSKeyValueObservation] = []

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
        self.stream = SRTStream(connection: self.connection)

        try super.init(
            ioStream: self.stream,
            initialAudioConfig: initialAudioConfig,
            initialVideoConfig: initialVideoConfig,
            initialCamera: initialCamera
        )

        let keyValueObservation = self.connection.observe(\.connected, options: [.new]) { [weak self] _, _ in
            guard let self = self else {
                return
            }
            if !connection.connected {
                delegate?.disconnection()
            }
        }
        self.keyValueObservations.append(keyValueObservation)
    }

    deinit {
        keyValueObservations.removeAll()
    }

    override func startStreaming(streamKey: String, url: String) throws {
        if streamKey.isEmpty {
            throw LiveStreamError.IllegalArgumentError("Stream key must not be empty")
        }
        if url.isEmpty {
            throw LiveStreamError.IllegalArgumentError("URL must not be empty")
        }
        if !self.isAudioConfigured || !self.isVideoConfigured {
            throw LiveStreamError.IllegalOperationError("Missing audio and/or video configuration")
        }
        guard var urlComponents = URLComponents(string: url) else {
            throw LiveStreamError.IllegalArgumentError("Invalid URL: \(url)")
        }
        if urlComponents.scheme != "srt" {
            throw LiveStreamError.IllegalArgumentError("Invalid URL scheme: \(urlComponents.scheme ?? "unknown")")
        }
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "streamid", value: streamKey))
        urlComponents.queryItems = queryItems

        let srtUrl = urlComponents.url
        Task {
            do {
                try await connection.open(srtUrl)
                stream.publish()
                delegate?.connectionSuccess()
            } catch {
                delegate?.connectionFailed(error.localizedDescription)
            }
        }
    }

    override func stopStreaming() {
        let isConnected = isConnected
        Task {
            await connection.close()
            if isConnected {
                delegate?.disconnection()
            }
        }
    }
}
