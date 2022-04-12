//
//  ViewController.swift
//  Example
//

import UIKit
import ApiVideoLiveStream

class ViewController: UIViewController {
    
    @IBOutlet private weak var preview: UIView!
    private var liveStream: ApiVideoLiveStream?
    private var errorRtmp: String? = nil
    
    private let alert = UIAlertController(title: "RTMP DISCONNECT", message: "", preferredStyle: .alert)
    private let front = UIImage(systemName: "camera.rotate.fill")
    private let back = UIImage(systemName: "camera.rotate")
    private let mute = UIImage(systemName: "speaker.slash.circle")
    private let unMute = UIImage(systemName: "speaker.circle")
    private let parameter = UIImage(systemName: "ellipsis")
    
    private var nc = NotificationCenter.default
    
    private let muteButton: UIButton = {
        let muteButton = UIButton()
        muteButton.setTitleColor(.orange, for: .normal)
        return muteButton
    }()
    
    private let startButton: UIButton = {
        let start = UIButton()
        start.setTitle("Start", for: .normal)
        start.setTitleColor(.orange, for: .normal)
        return start
    }()
    
    private let switchButton: UIButton = {
        let switchBtn = UIButton()
        switchBtn.setTitleColor(.orange, for: .normal)
        return switchBtn
    }()
    
    private let parameterButton: UIButton = {
        let paramBtn = UIButton()
        paramBtn.setTitleColor(.orange, for: .normal)
        return paramBtn
    }()
    
    
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
        let audioConfig = AudioConfig(bitrate: 32 * 1000)
        let videoConfig = VideoConfig(bitrate: 2 * 1024 * 1024, resolution: Resolution.RESOLUTION_720, fps: 30)
        do {
            liveStream = try ApiVideoLiveStream(initialAudioConfig: audioConfig, initialVideoConfig: videoConfig, preview: preview)
        } catch {
            print (error)
        }
        view.addSubview(muteButton)
        view.addSubview(startButton)
        view.addSubview(switchButton)
        view.addSubview(parameterButton)
        self.muteButton.setImage(unMute, for: .normal)
        self.switchButton.setImage(back, for: .normal)
        self.parameterButton.setImage(parameter, for: .normal)
        
        self.switchButton.addTarget(self, action: #selector(toggleSwitch), for: .touchUpInside)
        self.muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        self.startButton.addTarget(self, action: #selector(toggleLivestream), for: .touchUpInside)
        self.parameterButton.addTarget(self, action: #selector(navigateToParam), for: .touchUpInside)
        
        constraints()
        
        addAction()
        
        
    }
    
    func constraints(){
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        parameterButton.translatesAutoresizingMaskIntoConstraints = false
        
        muteButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        startButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        startButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        switchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        parameterButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        parameterButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        parameterButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 70).isActive = true
        parameterButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        startButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        
        muteButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor).isActive = true
        switchButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor).isActive = true
        
        muteButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        switchButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
        
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        liveStream?.audioConfig = SettingsManager.getAudioConfig()
        liveStream?.videoConfig = SettingsManager.getVideoConfig()
    }
    
    private func resetStartButton() {
        DispatchQueue.main.async {
            self.startButton.setTitle("Start", for: [])
            self.startButton.isSelected = false
        }
    }
    
    @objc func toggleLivestream(){
        if startButton.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            liveStream?.stopStreaming()
            startButton.setTitle("Start", for: [])
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            do {
                try liveStream?.startStreaming(streamKey: SettingsManager.streamKey, url: SettingsManager.endPoint)
            } catch LiveStreamError.IllegalArgumentError(let message){
                self.callAlert(code: message)
                resetStartButton()
           } catch {
               self.callAlert(code: "Failed to start streaming")
               resetStartButton()
            }
   
            liveStream?.onConnectionFailed = {(code) in
                self.callAlert(code: code)
                self.resetStartButton()
            }
            liveStream?.onDisconnect = {() in
                self.callAlert(code: "Disconnect")
                self.resetStartButton()
            }
            startButton.setTitle("Stop", for: [])
        }
        startButton.isSelected.toggle()
    }
    
    @objc func toggleSwitch(){
        if(liveStream?.camera == .front){
            liveStream?.camera = .back
            self.switchButton.setImage(self.back, for: .normal)
            
        } else if(liveStream?.camera == .back){
            liveStream?.camera = .front
            self.switchButton.setImage(self.front, for: .normal)
            
        }
    }
    
    @objc func toggleMute(){
        if(liveStream!.isMuted){
            liveStream?.isMuted = false
            self.muteButton.setImage(self.unMute, for: .normal)
        }else if(!liveStream!.isMuted){
            liveStream?.isMuted = true
            self.muteButton.setImage(self.mute, for: .normal)
        }
    }
    
    @objc func navigateToParam(){
        self.performSegue(withIdentifier: "paramSegue", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "paramSegue" {
            if segue.destination is SettingsViewController {

            }
        }
     }
    
    
}

