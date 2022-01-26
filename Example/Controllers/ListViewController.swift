//
//  ListViewController.swift
//  Example
//


import UIKit
import Foundation
import Accelerate

enum ParamUpdate {
    case Resolution
    case Framerate
    case AudioBitrate
}

struct SectionList {
    let title: String
    let options:[ListOptionType]
}

enum ListOptionType{
    case staticCell(model: ListOption)
}

struct ListOption{
    let title:String
    let icon: UIImage?
    let iconBackgroundColor: UIColor?
    var isSelected: Bool
    let handler: (()->Void)
}

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var list: [String]?
    var selectedItem: String?
    var titleList: String?
    var paramUpdate: ParamUpdate?
    var delegate: UpdateParamDelegate?
    
    var models = [SectionList]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .orange
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        
        configure()
        title = titleList
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let indexPath = IndexPath(row: getPosition(), section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        AppUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
    }
    
    private func getPosition()-> Int{
        var position = 0
        var i = 0
        for item in list!{
            if(item == self.selectedItem!){
                position = i
            }
            i = i + 1
        }
        return position
    }
    
    private func configure(){
        var option: [ListOptionType] = []
        for item in list! {
            var isSelected = false
            if(item == selectedItem){
                isSelected = true
            }
            option.append(.staticCell(model: ListOption(title: item, icon: nil, iconBackgroundColor: nil, isSelected: isSelected){
                self.selectedItem = item
            })
            )
        }
        models.append(SectionList(title: "Video", options: option))
    }
    
    private let tableView: UITableView = {
        
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(ListTableViewCell.self, forCellReuseIdentifier: ListTableViewCell.identifier)
        return table
    }()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section].options[indexPath.row]
        
        switch model.self {
        case .staticCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ListTableViewCell.identifier, for: indexPath) as? ListTableViewCell else{
                return UITableViewCell()
            }
            cell.layer.cornerRadius = 8
            cell.configure(with: model)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = models[indexPath.section].options[indexPath.row]
        switch type.self {
        case .staticCell(let model):
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.tintColor = .orange
                cell.accessoryType = .checkmark
            }
            model.handler()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
    
    @objc func handleDone(){
        switch paramUpdate {
        case .Resolution:
            delegate?.updateParamResolution(variable: selectedItem!)
        case .Framerate:
            delegate?.updateParamFramerate(variable: selectedItem!)
        case .AudioBitrate:
            delegate?.updateParamAudioBitrate(variable: selectedItem!)
        case .none:
            break
        }
        tableView.reloadData()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func handleCancel(){
        self.dismiss(animated: true, completion: nil)
    }
    
}
