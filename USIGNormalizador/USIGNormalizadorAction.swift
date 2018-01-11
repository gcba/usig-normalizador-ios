//
//  USIGNormalizadorAction.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 1/11/18.
//  Copyright © 2018 GCBA. All rights reserved.
//

import Foundation
import RxSwift
import Moya

private protocol USIGNormalizadorAction {
    var cell: ActionCell { get set }
    var visible: Variable<Bool> { get set }
    
    init(cell: ActionCell, visible: Bool)
}

private struct ActionCell {
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

private class PinAction: USIGNormalizadorAction {
    required init(cell: ActionCell, visible: Bool) {
        self.cell = cell
        self.visible = Variable<Bool>(visible)
    }
    
    var cell: ActionCell
    var visible: Variable<Bool>
}

private class NoNormalizationAction: USIGNormalizadorAction  {
    required init(cell: ActionCell, visible: Bool) {
        self.cell = cell
        self.visible = Variable<Bool>(visible)
    }
    
    var cell: ActionCell
    var visible: Variable<Bool>
}
