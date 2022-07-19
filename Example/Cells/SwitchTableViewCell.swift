//
//  SwitchTableViewCell.swift
//  Example
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    static let identifier = "SwitchTableViewCell"

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private let mySwitch: UISwitch = {
        let mySwitch = UISwitch()
        mySwitch.onTintColor = .orange
        return mySwitch
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        contentView.addSubview(mySwitch)
        contentView.clipsToBounds = true
        accessoryType = .none
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size: CGFloat = contentView.frame.size.height - 12

        mySwitch.sizeToFit()
        mySwitch.frame = CGRect(
            x: contentView.frame.size.width - mySwitch.frame.size.width - 20,
            y: (contentView.frame.size.height - mySwitch.frame.size.height) / 2,
            width: mySwitch.frame.size.width,
            height: mySwitch.frame.size.height
        )

        label.frame = CGRect(
            x: 25,
            y: 0,
            width: contentView.frame.size.width - 20,
            height: contentView.frame.size.height
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        mySwitch.isOn = false
    }

    public func configure(with model: SettingsSwitchOption) {
        label.text = model.title
        mySwitch.isOn = model.isOn
    }
}
