//
//  ViewController.swift
//  Example
//

import ApiVideoLiveStream
import UIKit

class ViewController: UIViewController {
    @IBOutlet private var preview: UIView!
    private var liveStream: ApiVideoLiveStream?
    private var errorRtmp: String?

    private let front = UIImage(systemName: "camera.rotate.fill")
    private let back = UIImage(systemName: "camera.rotate")
    private let mute = UIImage(systemName: "speaker.slash.circle")
    private let unMute = UIImage(systemName: "speaker.circle")
    private let parameter = UIImage(systemName: "ellipsis")

    private lazy var zoomGesture: UIPinchGestureRecognizer = .init(target: self, action: #selector(zoom(sender:)))
    private let pinchZoomMultiplier: CGFloat = 2.2

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

    private func callAlert(code: String, action: @escaping (() -> Void) = {}) {
        let alert = UIAlertController(title: "RTMP DISCONNECT", message: code, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            action()
        }

        alert.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            liveStream = try ApiVideoLiveStream(initialAudioConfig: SettingsManager.getAudioConfig(), initialVideoConfig: SettingsManager.getVideoConfig(), preview: preview)
        } catch {
            print(error)
        }
        view.addSubview(muteButton)
        view.addSubview(startButton)
        view.addSubview(switchButton)
        view.addSubview(parameterButton)
        muteButton.setImage(unMute, for: .normal)
        switchButton.setImage(back, for: .normal)
        parameterButton.setImage(parameter, for: .normal)

        switchButton.addTarget(self, action: #selector(toggleSwitch), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(toggleLivestream), for: .touchUpInside)
        parameterButton.addTarget(self, action: #selector(navigateToParam), for: .touchUpInside)

        preview.addGestureRecognizer(zoomGesture)

        constraints()
    }

    func constraints() {
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

    private func resetStartButton() {
        startButton.setTitle("Start", for: [])
        startButton.isSelected = false
    }

    @objc func toggleLivestream() {
        if startButton.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            liveStream?.stopStreaming()
            startButton.setTitle("Start", for: [])
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            do {
                try liveStream?.startStreaming(streamKey: SettingsManager.streamKey, url: SettingsManager.endPoint)
            } catch let LiveStreamError.IllegalArgumentError(message) {
                self.callAlert(code: message)
                resetStartButton()
            } catch {
                callAlert(code: "Failed to start streaming")
                resetStartButton()
            }

            liveStream?.onConnectionFailed = { code in
                DispatchQueue.main.async {
                    self.callAlert(code: code)
                    self.resetStartButton()
                }
            }
            liveStream?.onDisconnect = { () in
                DispatchQueue.main.async {
                    self.callAlert(code: "Disconnect")
                    self.resetStartButton()
                }
            }
            startButton.setTitle("Stop", for: [])
        }
        startButton.isSelected.toggle()
    }

    @objc func toggleSwitch() {
        if liveStream?.camera == .front {
            liveStream?.camera = .back
            switchButton.setImage(back, for: .normal)

        } else if liveStream?.camera == .back {
            liveStream?.camera = .front
            switchButton.setImage(front, for: .normal)
        }
    }

    @objc func toggleMute() {
        if liveStream!.isMuted {
            liveStream?.isMuted = false
            muteButton.setImage(unMute, for: .normal)
        } else if !liveStream!.isMuted {
            liveStream?.isMuted = true
            muteButton.setImage(mute, for: .normal)
        }
    }

    @objc func navigateToParam() {
        performSegue(withIdentifier: "paramSegue", sender: self)
    }

    private func updateConfig() {
        liveStream?.audioConfig = SettingsManager.getAudioConfig()
        liveStream?.videoConfig = SettingsManager.getVideoConfig()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "paramSegue" {
            if let navigationController = segue.destination as? UINavigationController {
                let settingsViewController = navigationController.topViewController as? SettingsViewController
                settingsViewController?.settingDidDisappear = {
                    self.updateConfig()
                }
            }
        }
    }

    @objc
    private func zoom(sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            if let liveStream = liveStream {
                liveStream.zoomRatio = liveStream.zoomRatio + (sender.scale - 1) * pinchZoomMultiplier
            }
            sender.scale = 1
        }
    }
}
