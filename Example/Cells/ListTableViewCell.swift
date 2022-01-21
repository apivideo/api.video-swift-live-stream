//
//  ListTableViewCell.swift
//  Example
//
//  Created by Romain Petit on 14/01/2022.
//

import UIKit

class ListTableViewCell: UITableViewCell {

    static let identifier = "ListTableViewCell"

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
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
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
    
    public func configure(with model: ListOption){
        label.text = model.title
        if(model.isSelected){
            self.setSelected(true, animated: false)
            self.tintColor = .orange
            self.accessoryType = .checkmark
        }
    }
}
