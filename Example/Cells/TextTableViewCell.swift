//
//  TextTableViewCell.swift
//  Example
//


import UIKit

class TextTableViewCell: UITableViewCell, UITextFieldDelegate {

    static let identifier = "TextTableViewCell"
    var delegate: UpdateParamDelegate?
    var type: TextFieldType?
    
    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    let myTextField: UITextField =  {
        let myTextField = UITextField()
        return myTextField
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        myTextField.delegate = self
        contentView.addSubview(label)
        contentView.addSubview(myTextField)
        contentView.clipsToBounds = true
        accessoryType = .none
    }
    
    required init?(coder: NSCoder){
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = CGRect(
            x: 25,
            y: 0,
            width: 120,
            height: contentView.frame.size.height
        )
        myTextField.sizeToFit()
        myTextField.frame = CGRect(
            x: label.frame.width + 50,
            y: 0,
            width: contentView.frame.size.width - label.frame.width - 55,
            height: contentView.frame.size.height
        )
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.default.post(name: UIResponder.keyboardDidShowNotification, object: self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.default.post(name: UIResponder.keyboardDidHideNotification, object: self)
        switch type {
        case .Endpoint:
            delegate?.updateParamEndpoint(variable: textField.text!)
        case .StreamKey:
            delegate?.updateParamStreamKey(variable: textField.text!)
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        myTextField.resignFirstResponder()
        return true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
    
    public func configure(with model: SettingsTextOption){
        label.text = model.title
        myTextField.text = model.defaultValue ?? ""
        type = model.type
    }

}
