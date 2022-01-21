//
//  SettingsViewController.swift
//  Example
//
//  Created by Romain Petit on 10/01/2022.
//

import Foundation
import UIKit
import ApiVideoLiveStream

enum TextFieldType{
    case Endpoint
    case StreamKey
}

struct Section {
    let title: String
    let options:[SettingsOptionType]
}

enum SettingsOptionType{
    case staticCell(model: SettingsOption)
    case switchCell(model: SettingsSwitchOption)
    case sliderCell(model: SettingsSliderOption)
    case textCell(model: SettingsTextOption)
}

struct SettingsTextOption{
    let title:String
    let defaultValue: String?
    let type: TextFieldType
    let handler: (()->Void)
}

struct SettingsSliderOption{
    let title:String
    let minValue: Double
    let maxValue: Double
    var defaultValue: Double
    let handler: (()->Void)
}

struct SettingsSwitchOption{
    let title:String
    var isOn: Bool
    let handler: (()->Void)
}

struct SettingsOption{
    let title:String
    let handler: (()->Void)
}

struct Setting{
    var resolution: Resolution
    var framerate: String
    var bitrate: Double
    var audioBitrate: String
    var sampleRate: String
    var isEchoCanceled: Bool
    var isNoiseCanceled: Bool
    var endpoint: String
    var streamKey: String
}

struct Resolution{
    var value: String
}

class SettingsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var liveStream: ApiVideoLiveStream?
    var videoLiveStream: VideoConfig?
    var audioLiveStream: AudioConfig?
    
    var delegate: DataEnteredDelegate?
    
    var models = [Section]()
    var selectedResolution = ""
    var selectedFramerate = ""
    var selectedAudioBitrate = ""
    var streamkey = ""
    var endpoint = "rtmp://broadcast.api.video/s"
    
    var selectedVideoBitrate: Int?

    // MARK: View events
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLiveStream()
        configure()
        title = "Settings"
        let center : NotificationCenter = .default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.lockOrientation(.portrait)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.sendDataBack(endpoint: endpoint, streamkey:streamkey)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        AppUtility.lockOrientation(.all)
    }
    
    // MARK: configure
    
    private func configureLiveStream(){
        // set video
        selectedResolution = "\(liveStream!.videoConfig.resolution.instance.width)x\(liveStream!.videoConfig.resolution.instance.height)"
        selectedFramerate = String(liveStream!.videoConfig.fps)
        selectedVideoBitrate = liveStream!.videoConfig.bitrate
        
        // set audio
        selectedAudioBitrate = "\(liveStream!.audioConfig.bitrate / 1000)Kbps"
    }
    
    private func configure(){
        models.append(Section(title: "Video", options: [
            .staticCell(model: SettingsOption(title: "Resolution") {
                var resolutions = [String]()
                resolutions.append("352x240")
                resolutions.append("640x360")
                resolutions.append("858x480")
                resolutions.append("1280x720")
                resolutions.append("1920x1080")
                resolutions.append("3860x2160")
                
                                
                let controller = ListViewController()
                controller.delegate = self
                
                controller.list = resolutions
                controller.selectedItem = self.selectedResolution
                controller.paramUpdate = .Resolution
                self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }),
            .staticCell(model: SettingsOption(title: "Framerate"){
                var framerates = [String]()
                framerates.append("24")
                framerates.append("30")
                framerates.append("60")
                framerates.append("120")
                
                let controller = ListViewController()
                controller.delegate = self
                
                controller.list = framerates
                controller.selectedItem = self.selectedFramerate
                controller.paramUpdate = .Framerate
                self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }),
            .sliderCell(model: SettingsSliderOption(title: "Bitrate", minValue: 500, maxValue: 3000000, defaultValue: Double(selectedVideoBitrate!)){
            })
        ]))
        
        models.append(Section(title: "Audio", options: [
            .staticCell(model: SettingsOption(title: "Bitrate"){
                var bitrates = [String]()
                bitrates.append("24Kbps")
                bitrates.append("64Kbps")
                bitrates.append("128Kbps")
                bitrates.append("192Kbps")
                
                let controller = ListViewController()
                controller.delegate = self
                
                controller.list = bitrates
                controller.selectedItem = self.selectedAudioBitrate
                controller.paramUpdate = .AudioBitrate
                self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            })
        ]))
        
        models.append(Section(title: "Endpoint", options: [
            .textCell(model: SettingsTextOption(title: "RTMP endpoint", defaultValue: "rtmp://broadcast.api.video/s", type: .Endpoint){
                print("\(TextTableViewCell().myTextField)")
            }),
            .textCell(model: SettingsTextOption(title: "Stream Key", defaultValue: nil, type: .StreamKey){
                
            })
        ]))
    }
    
    // MARK: display and hide keyboard
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight + 40, right: 0)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        })
    }
    
    //MARK: TableView
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }
    
    private let tableView: UITableView = {
        
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.identifier)
        table.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.identifier)
        table.register(SliderTableViewCell.self, forCellReuseIdentifier: SliderTableViewCell.identifier)
        table.register(TextTableViewCell.self, forCellReuseIdentifier: TextTableViewCell.identifier)
        return table
    }()
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].options.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section].options[indexPath.row]
        
        switch model.self {
        case .staticCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.identifier, for: indexPath) as? SettingTableViewCell else{
                return UITableViewCell()
            }
            cell.layer.cornerRadius = 8
            cell.configure(with: model)
            return cell
        case .switchCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.identifier, for: indexPath) as? SwitchTableViewCell else{
                return UITableViewCell()
            }
            cell.layer.cornerRadius = 8
            cell.selectionStyle = .none
            cell.configure(with: model)
            return cell
            
        case .sliderCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.identifier, for: indexPath) as? SliderTableViewCell else{
                return UITableViewCell()
            }
            cell.layer.cornerRadius = 8
            cell.configure(with: model)
            cell.delegate = self
            cell.selectionStyle = .none
            print("slider value on main : \(cell.sliderValue)")
            return cell
            
        case .textCell(let model):
            print(indexPath.section)
            print(indexPath.row)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextTableViewCell.identifier, for: indexPath) as? TextTableViewCell else{
                return UITableViewCell()
            }
            cell.delegate = self
            cell.layer.cornerRadius = 8
            cell.configure(with: model)
            cell.selectionStyle = .none
            return cell
        }
        
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].options[indexPath.row]
        switch type.self {
        case .staticCell(let model):
            model.handler()
        case .switchCell(let model):
            model.handler()
        case .sliderCell(let model):
            model.handler()
        case .textCell(let model):
            model.handler()
        }
    }
    
    
    // MARK: Convert functions
    private func getResolutionEnum(res: String) -> Resolutions{
        var resolution: Resolutions?
        switch res {
        case "352x240":
            resolution = Resolutions.RESOLUTION_240
        case "640x360":
            resolution = Resolutions.RESOLUTION_360
        case "858x480":
            resolution = Resolutions.RESOLUTION_480
        case "1280x720":
            resolution = Resolutions.RESOLUTION_720
        case "1920x1080":
            resolution = Resolutions.RESOLUTION_1080
        case "3860x2160":
            resolution = Resolutions.RESOLUTION_2160
        default:
            resolution = Resolutions.RESOLUTION_720
        }
        
        return resolution!
    }
    
    private func sampleRateToInt(sample: String) -> Int{
        var res: Int?
        res = Int(sample.dropLast(3))! * 1000
        return res!
    }
    
    private func audioBitrateToInt(bitrate: String) -> Int{
       var res: Int?
       res = Int(bitrate.dropLast(4))! * 1000
       return res!
   }
    
    private func isStereoToString(isStereo: Bool) -> String{
        if(isStereo){
            return "stereo"
        }else{
            return "mono"
        }
    }
    
    private func isStereoToBool(channel: String) -> Bool{
        var isStereo = false
        if(channel == "stereo"){
            isStereo = true
        }
        return isStereo
    }
}
// MARK : Extension
extension SettingsViewController: UpdateParamDelegate{
    func updateParamVideoBitrate(variable: Int) {
        selectedVideoBitrate = variable
        setVideo()
        print("video bitrate : \(String(describing: selectedVideoBitrate))")
    }
    
    func updateParamEndpoint(variable: String) {
        endpoint = variable
    }
    
    func updateParamStreamKey(variable: String) {
        streamkey = variable
    }
    
    func updateParamResolution(variable: String) {
        selectedResolution = variable
        setVideo()
    }
    
    func updateParamFramerate(variable: String) {
        selectedFramerate = variable
        setVideo()
    }
    
    func updateParamAudioBitrate(variable: String) {
        selectedAudioBitrate = variable
        setAudio()
    }
    
    private func setAudio(){
        let bitrate = audioBitrateToInt(bitrate: selectedAudioBitrate)
        let audio = AudioConfig(bitrate: bitrate)
        liveStream?.audioConfig = audio
    }
    
    private func setVideo(){
        let bitrate = selectedVideoBitrate!
        let resolution = getResolutionEnum(res: selectedResolution)
        let frame = Int(selectedFramerate)!
        let video = VideoConfig(bitrate: bitrate, resolution: resolution, fps: frame)
        liveStream?.videoConfig = video
    }
    
}
