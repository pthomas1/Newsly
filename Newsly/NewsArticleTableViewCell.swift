//
//  NewsArticleTableViewCell.swift
//  Newsly
//
//  Created by Peter Thomas on 4/28/17.
//  Copyright © 2017 Peter Thomas. All rights reserved.
//

import UIKit
import SDWebImage
import DateToolsSwift

class NewsArticleTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var articleImageView: UIImageView!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        articleImageView.layer.cornerRadius = 5
    }

    func populate(_ article:NewsArticle) {
        
        sourceLabel.text = article.source.name
        titleLabel.text = article.title
        
        let author = (article.author == nil || article.author! == article.source.name) ? "" : "\(article.author!.uppercased()) - "
        
        var publicationDateString = ""
        if let publicationDate = article.publicationDate {
            if (publicationDate.timeIntervalSinceNow > 0) {
                publicationDateString = "just now"
            } else {
                publicationDateString = publicationDate.timeAgoSinceNow
            }
        }
        authorLabel.text = "\(author)\(publicationDateString)"
        
        if let imageURL = article.imageURL, imageURL.scheme == "https" {

            articleImageView?.isHidden = false
            articleImageView?.sd_setImage(with: imageURL)
        } else {
            articleImageView?.image = nil
            articleImageView?.isHidden = true
        }
    }
}
