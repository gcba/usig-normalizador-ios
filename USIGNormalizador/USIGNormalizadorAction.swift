//
//  USIGNormalizadorAction.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 1/11/18.
//  Copyright © 2018 GCBA. All rights reserved.
//

import Foundation
import RxSwift

internal protocol USIGNormalizadorAction {
    var cell: ActionCell { get set }
    var visible: Variable<Bool> { get set }
    
    init(cell: ActionCell, visible: Bool)
}

internal struct ActionCell {
    init() {
        self.icon = nil
        self.iconTint = nil
        self.text = NSAttributedString(string: "")
        self.detailText = nil
    }
    
    init(text: NSAttributedString = NSAttributedString(string: ""), detailText: NSAttributedString? = nil) {
        self.init()
        
        self.text = text
        self.detailText = detailText
    }
    
    init(text: NSAttributedString = NSAttributedString(string: ""), detailText: NSAttributedString?, icon: UIImage? = nil, iconTint: UIColor? = nil) {
        self.init(text: text, detailText: detailText)
        
        self.icon = icon
        self.iconTint = iconTint
    }
    
    var icon: UIImage?
    var iconTint: UIColor?
    var text: NSAttributedString
    var detailText: NSAttributedString?
}

internal class PinAction: USIGNormalizadorAction {
    required init(cell: ActionCell, visible: Bool) {
        self.cell = cell
        self.visible = Variable<Bool>(visible)
    }
    
    var cell: ActionCell
    var visible: Variable<Bool>
}

internal class NoNormalizationAction: USIGNormalizadorAction  {
    required init(cell: ActionCell, visible: Bool) {
        self.cell = cell
        self.visible = Variable<Bool>(visible)
    }
    
    var cell: ActionCell
    var visible: Variable<Bool>
}
