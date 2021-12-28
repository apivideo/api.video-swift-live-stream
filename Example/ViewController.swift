//
//  ViewController.swift
//  Example
//

import UIKit
import ApiVideoLiveStream

class ViewController: UIViewController {
    
    @IBOutlet private weak var preview: UIView!
    @IBOutlet private weak var liveButton: UIButton!
    
    private var liveStream: ApiVideoLiveStream?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let audioConfig = AudioConfig(bitrate: 128 * 1024, sampleRate: 44100, stereo: true)
        let videoConfig = VideoConfig(bitrate: 2 * 1024 * 1024, resolution: Resolutions.RESOLUTION_720, fps: 30)
        do {
            liveStream = try ApiVideoLiveStream(initialAudioConfig: audioConfig, initialVideoConfig: videoConfig, preview: preview)
        } catch {
            print (error)
        }
    }
    
    @IBAction func on(publish: UIButton) {
        if publish.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            liveStream?.stopStreaming()
            publish.setTitle("Start", for: [])
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            liveStream?.startStreaming(streamKey: "mykey")
            publish.setTitle("Stop", for: [])
        }
        publish.isSelected.toggle()
    }
}

