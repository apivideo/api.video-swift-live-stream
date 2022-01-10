//
//  ViewController.swift
//  Example
//

import UIKit
import ApiVideoLiveStream

class ViewController: UIViewController {
    
    @IBOutlet private weak var preview: UIView!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var changeAudioButton: UIButton!
    
    private var liveStream: ApiVideoLiveStream?
    private var errorRtmp: String? = nil
    
    private let alert = UIAlertController(title: "RTMP DISCONNECT", message: "", preferredStyle: .alert)
    private let front = UIImage(systemName: "camera.rotate.fill")
    private let back = UIImage(systemName: "camera.rotate")
    private let mute = UIImage(systemName: "speaker.slash.circle")
    private let unMute = UIImage(systemName: "speaker.circle")
    
    private func callAlert(code: String?){
        DispatchQueue.main.async {
            self.alert.message = code ?? "something went wrong, try again later"
            
            self.present(self.alert, animated: true, completion: nil)
        }
    }
    
    private func addAction(){
        self.alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
                case .default:
                print("default")
                
                case .cancel:
                print("cancel")
                
                case .destructive:
                print("destructive")
                
            @unknown default:
                fatalError()
            }
        }))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let audioConfig = AudioConfig(bitrate: 128 * 1024, sampleRate: 44100, stereo: true)
        let videoConfig = VideoConfig(bitrate: 2 * 1024 * 1024, resolution: Resolutions.RESOLUTION_720, fps: 30)
        addAction()
        self.switchCameraButton.setImage(back, for: .selected)
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
            liveStream?.onConnectionFailed = {(code) in
                self.liveStream?.stopStreaming()
                self.callAlert(code: code)
                DispatchQueue.main.async {
                    publish.setTitle("Start", for: [])
                }
                
            }
            publish.setTitle("Stop", for: [])
        }
        publish.isSelected.toggle()
    }
    @IBAction func switchCamera(_ sender: Any) {
        if(liveStream?.camera == .front){
            liveStream?.camera = .back
            self.switchCameraButton.setImage(self.back, for: .normal)
            
        } else if(liveStream?.camera == .back){
            liveStream?.camera = .front
            self.switchCameraButton.setImage(self.front, for: .normal)
            
        }
    }
    
    @IBAction func muteUnMute(_ sender: Any) {
        if(liveStream!.isMuted){
            liveStream?.isMuted = false
            self.changeAudioButton.setImage(self.unMute, for: .normal)
        }else if(!liveStream!.isMuted){
            liveStream?.isMuted = true
            self.changeAudioButton.setImage(self.mute, for: .normal)
        }
    }
    
}

