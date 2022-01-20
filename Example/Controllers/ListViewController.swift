//
//  ListViewController.swift
//  Example
//
//  Created by Romain Petit on 14/01/2022.
//

import UIKit
import Foundation
import Accelerate

enum ParamUpdate {
    case Resolution
    case Framerate
    case NbChannels
    case AudioBitrate
    case SampleRate
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
        print("the list is : \(String(describing: list))")
        print("the selected Item is : \(String(describing: selectedItem))")
        title = titleList
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("selectedItem : \(String(describing: selectedItem))")
        
        let indexPath = IndexPath(row: getPosition(), section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
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
                print("item : \(item) selected")
                self.selectedItem = item
                print("selectedItem : \(self.selectedItem!)")
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
        print("handleDone : \(selectedItem!)")
        switch paramUpdate {
        case .Resolution:
            delegate?.updateParamResolution(variable: selectedItem!)
        case .Framerate:
            delegate?.updateParamFramerate(variable: selectedItem!)
        case .NbChannels:
            delegate?.updateParamNbChannels(variable: selectedItem!)
        case .AudioBitrate:
            delegate?.updateParamAudioBitrate(variable: selectedItem!)
        case .SampleRate:
            delegate?.updateParamSampleRate(variable: selectedItem!)
        case .none:
            break
        }
        tableView.reloadData()
        self.dismiss(animated: true, completion: nil)
        print("done")
    }
    
    @objc func handleCancel(){
        self.dismiss(animated: true, completion: nil)
    }
    
}
