//
//  NewsSourceTableViewCell.swift
//  Newsly
//
//  Created by Peter Thomas on 4/28/17.
//  Copyright © 2017 Peter Thomas. All rights reserved.
//

import UIKit
import SDWebImage

class NewsSourceTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func populate(_ newsSource:NewsSource, isSelected:Bool) {

        self.nameLabel.text = newsSource.name
        self.descriptionLabel.text = newsSource.description
        
        if isSelected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
}
