import ApiVideoLiveStream
import AVKit
import InAppSettingsKit
import UIKit

class MainViewController: UIViewController {
    @IBOutlet private var preview: UIView!
    private lazy var liveStream: ApiVideoLiveStream = {
        var liveStream: ApiVideoLiveStream
        do {
            // Create liveStream object
            let liveStream = try ApiVideoLiveStream(
                preview: preview,
                initialAudioConfig: SettingsManager.audioConfig,
                initialVideoConfig: SettingsManager.videoConfig
            )

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

    private func callAlert(_ message: String, title: String = "Error", action: @escaping () -> Void = {}) {
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
        self.liveStream.delegate = self

        view.addSubview(self.muteButton)
        view.addSubview(self.streamingButton)
        view.addSubview(self.switchButton)
        view.addSubview(self.parameterButton)
        self.muteButton.setImage(self.unMute, for: .normal)
        self.switchButton.setImage(self.back, for: .normal)
        self.parameterButton.setImage(self.parameter, for: .normal)

        self.switchButton.addTarget(self, action: #selector(self.toggleSwitch), for: .touchUpInside)
        self.muteButton.addTarget(self, action: #selector(self.toggleMute), for: .touchUpInside)
        self.streamingButton.addTarget(self, action: #selector(self.toggleStreaming), for: .touchUpInside)
        self.parameterButton.addTarget(self, action: #selector(self.navigateToParam), for: .touchUpInside)

        self.preview.addGestureRecognizer(self.zoomGesture)

        self.constraints()
    }

    func constraints() {
        self.muteButton.translatesAutoresizingMaskIntoConstraints = false
        self.streamingButton.translatesAutoresizingMaskIntoConstraints = false
        self.switchButton.translatesAutoresizingMaskIntoConstraints = false
        self.parameterButton.translatesAutoresizingMaskIntoConstraints = false

        self.muteButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        self.muteButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.streamingButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        self.streamingButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.switchButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        self.switchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.parameterButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.parameterButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        self.parameterButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 70).isActive = true
        self.parameterButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true

        self.streamingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.streamingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true

        self.muteButton.centerYAnchor.constraint(equalTo: self.streamingButton.centerYAnchor).isActive = true
        self.switchButton.centerYAnchor.constraint(equalTo: self.streamingButton.centerYAnchor).isActive = true

        self.muteButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        self.switchButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
    }

    private func resetStartButton() {
        DispatchQueue.main.async {
            self.streamingButton.setTitle("Start", for: [])
            self.streamingButton.isSelected = false
        }
    }

    @objc
    func toggleStreaming() {
        if self.streamingButton.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            self.liveStream.stopStreaming()
            self.resetStartButton()
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            do {
                if SettingsManager.streamKey.isEmpty {
                    self.callAlert("The stream key is not set. Please set it in Settings.")
                    return
                }
                if SettingsManager.rtmpUrl.isEmpty {
                    self.callAlert("The stream key is not set. Please set it in Settings.")
                    return
                }

                try self.liveStream.startStreaming(streamKey: SettingsManager.streamKey, url: SettingsManager.rtmpUrl)

                self.streamingButton.setTitle("Stop", for: [])
                self.streamingButton.isSelected = true
            } catch {
                self.callAlert("Failed to start streaming: \(error)")
            }
        }
    }

    @objc
    func toggleSwitch() {
        if self.liveStream.cameraPosition == .front {
            self.liveStream.cameraPosition = .back
            self.switchButton.setImage(self.back, for: .normal)
        } else if self.liveStream.cameraPosition == .back {
            self.liveStream.cameraPosition = .front
            self.switchButton.setImage(self.front, for: .normal)
        }
    }

    @objc
    func toggleMute() {
        self.liveStream.isMuted.toggle()
        if self.liveStream.isMuted {
            self.muteButton.setImage(self.unMute, for: .normal)
        } else {
            self.muteButton.setImage(self.mute, for: .normal)
        }
    }

    @objc
    func navigateToParam() {
        performSegue(withIdentifier: "paramSegue", sender: self)
    }

    private func updateConfig() {
        self.liveStream.audioConfig = SettingsManager.audioConfig
        self.liveStream.videoConfig = SettingsManager.videoConfig
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
            self.liveStream.zoomRatio += (sender.scale - 1) * self.pinchZoomMultiplier
            sender.scale = 1
        }
    }
}

// MARK: IASKSettingsDelegate

extension MainViewController: IASKSettingsDelegate {
    func settingsViewControllerDidEnd(_ settingsViewController: IASKAppSettingsViewController) {
        settingsViewController.dismiss(animated: true, completion: nil)
        self.updateConfig()
    }
}

// MARK: ApiVideoLiveStreamDelegate

extension MainViewController: ApiVideoLiveStreamDelegate {
    /// Called when the connection to the rtmp server is successful
    func connectionSuccess() {
        print("onConnectionSuccess")
    }

    /// Called when the connection to the rtmp server failed
    func connectionFailed(_: String) {
        self.callAlert("Failed to connect to the server")
        self.resetStartButton()
    }

    /// Called when the connection to the rtmp server is closed
    func disconnection() {
        print("onDisconnect")
        self.resetStartButton()
    }

    /// Called if an error happened during the audio configuration
    func audioError(_ error: Error) {
        self.callAlert("Audio error: \(error.localizedDescription)")
    }

    /// Called if an error happened during the video configuration
    func videoError(_ error: Error) {
        self.callAlert("Video error: \(error.localizedDescription)")
    }
}
