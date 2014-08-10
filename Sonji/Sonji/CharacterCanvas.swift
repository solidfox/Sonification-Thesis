//
//  CharacterCanvas.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/5/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

class CharacterCanvas: PointSequenceView {
    func animateFailure() {
        self.clear()
    }
    
    func animateSuccess() {
        self.clear()
    }
    
    func _defaultSettings() {
        self.opaque = false
        self.interpolatePoints = true
    }
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        self._defaultSettings()
    }
    
    init(frame: CGRect) {
        super.init(frame:frame)
        self._defaultSettings()
    }
}
