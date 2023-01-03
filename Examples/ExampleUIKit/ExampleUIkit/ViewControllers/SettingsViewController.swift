import ApiVideoLiveStream
import Foundation
import UIKit
import InAppSettingsKit

class SettingsViewController: IASKAppSettingsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        showDoneButton = true
        showCreditsFooter = false
    }

    @objc
    func settingDidChange(notification: Notification?) {
        guard let notification = notification,
              let paramChanged = notification.userInfo?.first,
              let key = paramChanged.key as? String
        else {
            return
        }

        switch key {
        case "VideoBitrateSlider":
            if let value = paramChanged.value as? Float {
                UserDefaults.standard.set(Int(value), forKey: "VideoBitrateValue")
            }

        default:
            // Do nothing
            break
        }
    }
}
