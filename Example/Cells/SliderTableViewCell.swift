//
//  SliderTableViewCell.swift
//  Example
//

import UIKit

class SliderTableViewCell: UITableViewCell {
    static let identifier = "SliderTableViewCell"
    var sliderValue = 0
    var delegate: UpdateParamDelegate?

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    let mySlider: UISlider = {
        let mySwitch = UISlider()
        return mySwitch
    }()

    private let currentValueLabel: UILabel = {
        let currentValueLabel = UILabel()
        currentValueLabel.numberOfLines = 1
        return currentValueLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        contentView.addSubview(mySlider)
        mySlider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        contentView.addSubview(currentValueLabel)
        contentView.clipsToBounds = true
        accessoryType = .none
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    @objc func sliderValueDidChange(_ sender: UISlider!) {
        let roundedStepValue = round(sender.value)
        sender.value = roundedStepValue

        sliderValue = Int(roundedStepValue)
        delegate?.updateParamVideoBitrate(variable: sliderValue)

        DispatchQueue.main.async {
            self.currentValueLabel.text = String(Int(roundedStepValue))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size: CGFloat = contentView.frame.size.height - 12
        let imageSize: CGFloat = size / 1.5

        label.frame = CGRect(
            x: 25,
            y: 0,
            width: 100,
            height: contentView.frame.size.height
        )

        currentValueLabel.frame = CGRect(
            x: contentView.frame.size.width - 85,
            y: 0,
            width: 100,
            height: contentView.frame.size.height
        )

        mySlider.frame = CGRect(
            x: 90,
            y: (size - imageSize) / 2,
            width: contentView.frame.size.width - currentValueLabel.frame.width - label.frame.width + 20,
            height: mySlider.frame.size.height
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        mySlider.maximumValue = Float(500)
        mySlider.minimumValue = Float(500)
        currentValueLabel.text = nil
    }

    public func configure(with model: SettingsSliderOption) {
        label.text = model.title
        mySlider.minimumValue = Float(model.minValue)
        mySlider.maximumValue = Float(model.maxValue)
        mySlider.value = Float(model.defaultValue)
        currentValueLabel.text = String(Int(round(mySlider.value)))
    }
}
