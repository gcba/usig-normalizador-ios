//
//  USIGNormalizadorCell.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 14/01/2018.
//  Copyright © 2018 GCBA. All rights reserved.
//

import Foundation
import UIKit

internal class USIGNormalizadorCell: UITableViewCell {
    private let imageViewWidth: CGFloat = 19
    private let imageViewPaddingLeft: CGFloat = 15
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = imageView, let textLabel = textLabel, let detailTextLabel = detailTextLabel, imageView.image != nil {
            imageView.frame = CGRect(origin: imageView.frame.origin, size: CGSize(width: imageViewWidth, height: imageView.frame.size.height))
            imageView.contentMode = .scaleAspectFit
            imageView.autoresizingMask = .flexibleHeight
            
            textLabel.frame = CGRect(
                origin: CGPoint(x: imageView.frame.origin.x + imageView.frame.size.width + imageViewPaddingLeft, y: textLabel.frame.origin.y),
                size: textLabel.frame.size
            )
            
            detailTextLabel.frame = CGRect(
                origin: CGPoint(x: imageView.frame.origin.x + imageView.frame.size.width + imageViewPaddingLeft, y: detailTextLabel.frame.origin.y),
                size: detailTextLabel.frame.size
            )
        }
    }
}
