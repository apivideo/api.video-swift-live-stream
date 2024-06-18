//
//  ApiVideoLiveStream.swift
//

import AVFoundation
import Foundation
import HaishinKit
#if !os(macOS)
import UIKit
#endif
import VideoToolbox

public class ApiVideoLiveStream {
    private let rtmpStream: RtmpLiveStream
    private let srtStream: SrtLiveStream
    
    private var currentStream: IOLiveStream
    
    private let preview: IOStreamView?

    /// The delegate of the ApiVideoLiveStream
    public weak var delegate: ApiVideoLiveStreamDelegate? {
        didSet {
            rtmpStream.delegate = delegate
            srtStream.delegate = delegate
        }
    }

    ///  Getter and Setter for an AudioConfig
    public var audioConfig: AudioConfig {
        get {
            currentStream.audioConfig
        }
        set {
            rtmpStream.audioConfig = newValue
            srtStream.audioConfig = newValue
        }
    }

    /// Getter and Setter for a VideoConfig
    public var videoConfig: VideoConfig {
        get {
            currentStream.videoConfig
        }
        set {
            rtmpStream.videoConfig = newValue
            srtStream.videoConfig = newValue
        }
    }

    /// Getter and Setter for the Bitrate number for the video
    public var videoBitrate: Int {
        get {
            currentStream.videoBitrate
        }
        set(newValue) {
            rtmpStream.videoBitrate = newValue
            srtStream.videoBitrate = newValue
        }
    }

    private var lastCamera: AVCaptureDevice?

    /// Camera position
    public var cameraPosition: AVCaptureDevice.Position {
        get {
            currentStream.cameraPosition
        }
        set(newValue) {
            currentStream.cameraPosition = newValue
        }
    }

    /// Camera device
    public var camera: AVCaptureDevice? {
        get {
            currentStream.camera
        }
        set(newValue) {
            currentStream.camera = newValue
        }
    }

    /// Mutes or unmutes audio capture.
    public var isMuted: Bool {
        get {
            currentStream.isMuted
        }
        set(newValue) {
            rtmpStream.isMuted = newValue
            srtStream.isMuted = newValue
        }
    }

    #if os(iOS)
    /// Zoom on the video capture
    public var zoomRatio: CGFloat {
        get {
            currentStream.zoomRatio
        }
        set(newValue) {
            rtmpStream.zoomRatio = newValue
            srtStream.zoomRatio = newValue
        }
    }
    #endif

    /// Creates a new ApiVideoLiveStream object with a IOStreamView
    /// - Parameters:
    ///   - preview: The IOStreamView where to display the preview of camera. Nil if you don
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    ///   - initialCamera: The ApiVideoLiveStream's initial camera device
    public init(
        preview: IOStreamView?,
        initialAudioConfig: AudioConfig? = AudioConfig(),
        initialVideoConfig: VideoConfig? = VideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    ) throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()

        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        #endif
                
        rtmpStream = try RtmpLiveStream(initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig, initialCamera: initialCamera)
       
        // Default to RTMP
        currentStream = rtmpStream
        
        // Attach preview
        self.preview = preview
        if let preview {
            currentStream.attachPreview(preview)
        }
        
        // Init SRT later to get the preview quickly
        srtStream = try SrtLiveStream(initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig, initialCamera: nil)
        
        #if !os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #endif

        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.orientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        #endif
 
    }
    
    /// Creates a new ApiVideoLiveStream object without a preview
    /// - Parameters:
    ///   - initialAudioConfig: The ApiVideoLiveStream's initial AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's initial VideoConfig
    ///   - initialCamera: The ApiVideoLiveStream's initial camera device
    public convenience init(
        initialAudioConfig: AudioConfig? = AudioConfig(),
        initialVideoConfig: VideoConfig? = VideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    ) throws {
        try self.init(preview: nil, initialAudioConfig: initialAudioConfig, initialVideoConfig: initialVideoConfig, initialCamera: initialCamera)
    }
    
    #if !os(macOS)
    /// Creates a new ApiVideoLiveStream object with a UIView as preview
    /// - Parameters:
    ///   - preview: The UIView where to display the preview of camera
    ///   - initialAudioConfig: The ApiVideoLiveStream's new AudioConfig
    ///   - initialVideoConfig: The ApiVideoLiveStream's new VideoConfig
    ///   - initialCamera: The ApiVideoLiveStream's initial camera device
    public convenience init(
        preview: UIView,
        initialAudioConfig: AudioConfig? = AudioConfig(),
        initialVideoConfig: VideoConfig? = VideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    ) throws {
        let mthkView = MTHKView(frame: preview.bounds)
        mthkView.translatesAutoresizingMaskIntoConstraints = false
        mthkView.videoGravity = AVLayerVideoGravity.resizeAspectFill

        preview.addSubview(mthkView)

        let maxWidth = mthkView.widthAnchor.constraint(lessThanOrEqualTo: preview.widthAnchor)
        let maxHeight = mthkView.heightAnchor.constraint(lessThanOrEqualTo: preview.heightAnchor)
        let width = mthkView.widthAnchor.constraint(equalTo: preview.widthAnchor)
        let height = mthkView.heightAnchor.constraint(equalTo: preview.heightAnchor)
        let centerX = mthkView.centerXAnchor.constraint(equalTo: preview.centerXAnchor)
        let centerY = mthkView.centerYAnchor.constraint(equalTo: preview.centerYAnchor)

        width.priority = .defaultHigh
        height.priority = .defaultHigh

        NSLayoutConstraint.activate([
            maxWidth, maxHeight, width, height, centerX, centerY
        ])
        
        try self.init(
            preview: mthkView as IOStreamView,
            initialAudioConfig: initialAudioConfig,
            initialVideoConfig: initialVideoConfig,
            initialCamera: initialCamera
        )
    }
    #endif

    deinit {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        #endif
        #if !os(macOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        #endif
    }

    /// Start your livestream
    /// - Parameters:
    ///   - streamKey: The key of your live
    ///   - url: The url of your rtmp server, by default it's rtmp://broadcast.api.video/s
    /// - Returns: Void
    public func startStreaming(streamKey: String, url: String = "rtmp://broadcast.api.video/s") throws {
        if (currentStream.isConnected) {
            throw LiveStreamError.IllegalOperationError("Already streaming")
        }
        
        guard let parsedUrl = URL(string: url),
              let scheme = parsedUrl.scheme
           else {
            throw LiveStreamError.IllegalArgumentError("Invalid URL: \(url)")
        }
        
        let currentStream: IOLiveStream
        switch scheme {
            case "rtmp":
                currentStream = rtmpStream
            case "srt":
                currentStream = srtStream
            default:
                throw LiveStreamError.IllegalArgumentError("Invalid scheme: \(scheme)")
        }
        
        // Switch stream if necessary
        if (currentStream !== self.currentStream) {
            if let preview {
                currentStream.camera = self.currentStream.camera
                currentStream.attachPreview(preview)
            }
            self.currentStream = currentStream
        }

        try currentStream.startStreaming(streamKey: streamKey, url: url)
    }

    /// Stop your livestream
    /// - Returns: Void
    public func stopStreaming() {
        let isConnected = self.currentStream.isConnected
        self.currentStream.stopStreaming()
        if isConnected {
            self.delegate?.disconnection()
        }
    }

    public func startPreview() {
        currentStream.startPreview()
    }

    public func stopPreview() {
        currentStream.stopPreview()
    }

    #if os(iOS)
    @objc
    private func orientationDidChange(_: Notification) {
        self.rtmpStream.orientationDidChange()
        self.srtStream.orientationDidChange()
       
    }
    #endif

    #if !os(macOS)
    @objc
    private func didEnterBackground(_: Notification) {
        self.stopStreaming()
    }
    #endif
}

public protocol ApiVideoLiveStreamDelegate: AnyObject {
    /// Called when the connection to the rtmp server is successful
    func connectionSuccess()

    /// Called when the connection to the rtmp server failed
    func connectionFailed(_ code: String)

    /// Called when the connection to the rtmp server is closed
    func disconnection()

    /// Called if an error happened during the audio configuration
    func audioError(_ error: Error)

    /// Called if an error happened during the video configuration
    func videoError(_ error: Error)
}
