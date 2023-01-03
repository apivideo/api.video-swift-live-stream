import ApiVideoLiveStream
import InAppSettingsKit
import AVKit
import UIKit

class MainViewController: UIViewController {
    @IBOutlet private var preview: UIView!
    private lazy var liveStream: ApiVideoLiveStream = {
        var liveStream: ApiVideoLiveStream
        do {
            // Create liveStream object
            let liveStream = try ApiVideoLiveStream(
                    initialAudioConfig: SettingsManager.audioConfig,
                    initialVideoConfig: SettingsManager.videoConfig,
                    preview: preview)

            return liveStream
        } catch {
            fatalError("Can't create liveStream: \(error)")
        }
    }()

    private let front = UIImage(systemName: "camera.rotate.fill")
    private let back = UIImage(systemName: "camera.rotate")
    private let mute = UIImage(systemName: "mic.slash.fill")
    private let unMute = UIImage(systemName: "mic.fill")
    private let parameter = UIImage(systemName: "ellipsis")

    private lazy var zoomGesture: UIPinchGestureRecognizer = .init(target: self, action: #selector(zoom(sender:)))
    private let pinchZoomMultiplier: CGFloat = 2.2

    private let muteButton: UIButton = {
        let muteButton = UIButton()
        muteButton.setTitleColor(.orange, for: .normal)
        return muteButton
    }()

    private let streamingButton: UIButton = {
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

    private func callAlert(_ message: String, title: String = "Error", action: @escaping () -> Void = {
    }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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

        // Register default NSUserDefaults
        if let defaultDict = SettingsViewController().settingsReader?.gatherDefaultsLimited(toEditableFields: true) {
            UserDefaults.standard.register(defaults: defaultDict)
        }

        // Call to explicitly create liveStream
        liveStream.delegate = self

        view.addSubview(muteButton)
        view.addSubview(streamingButton)
        view.addSubview(switchButton)
        view.addSubview(parameterButton)
        muteButton.setImage(unMute, for: .normal)
        switchButton.setImage(back, for: .normal)
        parameterButton.setImage(parameter, for: .normal)

        switchButton.addTarget(self, action: #selector(toggleSwitch), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        streamingButton.addTarget(self, action: #selector(toggleStreaming), for: .touchUpInside)
        parameterButton.addTarget(self, action: #selector(navigateToParam), for: .touchUpInside)

        preview.addGestureRecognizer(zoomGesture)

        constraints()
    }

    func constraints() {
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        streamingButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        parameterButton.translatesAutoresizingMaskIntoConstraints = false

        muteButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        streamingButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        streamingButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        switchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        parameterButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        parameterButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        parameterButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 70).isActive = true
        parameterButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true

        streamingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        streamingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true

        muteButton.centerYAnchor.constraint(equalTo: streamingButton.centerYAnchor).isActive = true
        switchButton.centerYAnchor.constraint(equalTo: streamingButton.centerYAnchor).isActive = true

        muteButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        switchButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
    }

    private func resetStartButton() {
        DispatchQueue.main.async {
            self.streamingButton.setTitle("Start", for: [])
            self.streamingButton.isSelected = false
        }
    }

    // swiftlint:disable line_length
    @objc
    func toggleStreaming() {
        if streamingButton.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            liveStream.stopStreaming()
            resetStartButton()
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            do {
                if SettingsManager.streamKey.isEmpty {
                    callAlert("The stream key is not set. Please set it in Settings.")
                    return
                }
                if SettingsManager.rtmpUrl.isEmpty {
                    callAlert("The stream key is not set. Please set it in Settings.")
                    return
                }

                try liveStream.startStreaming(streamKey: SettingsManager.streamKey, url: SettingsManager.rtmpUrl)

                streamingButton.setTitle("Stop", for: [])
                streamingButton.isSelected = true
            } catch {
                callAlert("Failed to start streaming: \(error)")
            }
        }
    }

    @objc
    func toggleSwitch() {
        if liveStream.cameraPosition == .front {
            liveStream.cameraPosition = .back
            switchButton.setImage(back, for: .normal)
        } else if liveStream.cameraPosition == .back {
            liveStream.cameraPosition = .front
            switchButton.setImage(front, for: .normal)
        }
    }

    @objc
    func toggleMute() {
        liveStream.isMuted.toggle()
        if liveStream.isMuted {
            muteButton.setImage(unMute, for: .normal)
        } else {
            muteButton.setImage(mute, for: .normal)
        }
    }

    @objc
    func navigateToParam() {
        performSegue(withIdentifier: "paramSegue", sender: self)
    }

    private func updateConfig() {
        liveStream.audioConfig = SettingsManager.audioConfig
        liveStream.videoConfig = SettingsManager.videoConfig
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "paramSegue" {
            guard let navigationController = segue.destination as? UINavigationController else {
                print("Can't get navigation controller")
                return
            }
            let settingsViewController = SettingsViewController()
            settingsViewController.delegate = self
            navigationController.pushViewController(settingsViewController, animated: true)
        }
    }

    @objc
    private func zoom(sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            liveStream.zoomRatio += (sender.scale - 1) * pinchZoomMultiplier
            sender.scale = 1
        }
    }
}

extension MainViewController: IASKSettingsDelegate {
    func settingsViewControllerDidEnd(_ settingsViewController: IASKAppSettingsViewController) {
        settingsViewController.dismiss(animated: true, completion: nil)
        updateConfig()
    }
}

extension MainViewController: ApiVideoLiveStreamDelegate {
    /// Called when the connection to the rtmp server is successful
    func onConnectionSuccess() {
        print("onConnectionSuccess")
    }

    /// Called when the connection to the rtmp server failed
    func onConnectionFailed(_ code: String) {
        callAlert("Failed to connect to the server")
        resetStartButton()
    }

    /// Called when the connection to the rtmp server is closed
    func onDisconnect() {
        print("onDisconnect")
        resetStartButton()
    }

    /// Called if an error happened during the audio configuration
    func audioError(_ error: Error) {
        callAlert("Audio error: \(error.localizedDescription)")
    }

    /// Called if an error happened during the video configuration
    func videoError(_ error: Error) {
        callAlert("Video error: \(error.localizedDescription)")
    }
}
