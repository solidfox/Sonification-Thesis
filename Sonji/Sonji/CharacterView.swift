//
//  StrokeView.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/2/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit
import QuartzCore
//import KanjiVGKit

class CharacterView: UIView {
    
    var _strokeViews: [StrokeView] = []
    
    var strokeColor: UIColor = UIColor.blackColor() {
    didSet {
        self.setNeedsDisplay()
    }
    }

    var strokes: [KVGStroke] = [] {
    didSet {
        _strokeViews = []
        for subview in subviews as [UIView] {
            subview.removeFromSuperview()
        }
        for stroke in strokes {
            let strokeView = StrokeView(frame: self.bounds, stroke: stroke)
            _strokeViews += strokeView
            self.addSubview(strokeView)
        }
        _updateShownStrokes()
    }
    }
    
    var shownStrokes: Range<Int>? {
    didSet {
        _updateShownStrokes()
    }
    }
    
    func _updateShownStrokes() {
        if let shownStrokes = self.shownStrokes {
            for i in 0..<_strokeViews.count {
                if shownStrokes.startIndex <= i && i < shownStrokes.endIndex {
                    _strokeViews[i].hidden = false
                } else {
                    _strokeViews[i].hidden = true
                }
            }
        }
    }
    
    var characterSize: CGFloat = 109
    
    func flashStrokeWithIndex(index:Int) {
        if 0 <= index && index < _strokeViews.count {
            _strokeViews[index].flashWithColor(UIColor.blueColor())
        }
    }
    
    func animateDrawingCharacter(callback: (() -> ())? = nil) {
        _strokeViews[0].animateStroke() {
            self._animateStrokeAfter(strokeView: $0, withCallback: callback)
        }
    }
    
    func _animateStrokeAfter(strokeView soughtStrokeView:StrokeView, withCallback callback: (() -> ())? = nil) {
        for (index, strokeView) in enumerate(_strokeViews) {
            if soughtStrokeView == strokeView {
                if index + 1 < _strokeViews.count {
                    _strokeViews[index+1].animateStroke() {
                        self._animateStrokeAfter(strokeView: $0, withCallback: callback)
                    }
                } else {
                    UIView.animateWithDuration(1,
                        animations: {
                            self.alpha = 0
                        },
                        completion: {_ in
                            self.shownStrokes = 0..<0
                            self.alpha = 1
                            callback?()
                        })
                }
                break
            }
        }
    }
    
    init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
    }
    
    init(coder aDecoder: NSCoder!)
    {
        super.init(coder: aDecoder)
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

}
