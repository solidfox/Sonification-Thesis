//
//  StrokeView.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/2/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit
//import BezierKit
//import KanjiVGKit
import QuartzCore

class StrokeView: UIView {
    
    let stroke: KVGStroke
    var _callbacks: [(String,(StrokeView) -> ())] = []
    var _path: CGPath!
    var _shapeLayer: CAShapeLayer
    var _hiddenAfterAnimation:Bool = false
    var strokeColor:UIColor {
    get {
        return UIColor(CGColor: _shapeLayer.strokeColor)
    }
    set {
        _shapeLayer.strokeColor = newValue.CGColor
    }
    }
    var lineWidth: CGFloat {
    get {
        return _shapeLayer.lineWidth
    }
    set {
        _shapeLayer.lineWidth = newValue
    }
    }
    
    override var hidden:Bool {
    willSet{
        self._hiddenAfterAnimation = newValue
    }
    }
    
    
    init(frame: CGRect, stroke: KVGStroke) {
        self.stroke = stroke
        self._shapeLayer = CAShapeLayer()
        _shapeLayer.strokeColor = UIColor.blackColor().CGColor
        _shapeLayer.fillColor = UIColor.clearColor().CGColor
        _shapeLayer.lineWidth = 5
        _shapeLayer.lineCap = kCALineCapRound
        _shapeLayer.lineJoin = kCALineJoinRound
        
        super.init(frame: frame)
        
        _shapeLayer.path = _transformedPath.CGPath
        self.layer.addSublayer(_shapeLayer)
        
        self.opaque = false
    }
    
    func flashWithColor(flashColor:UIColor) {
        let previousColor = self.strokeColor
        let previousAlpha = self.alpha
        var targetAlpha:CGFloat = 0.0
        var targetColor = flashColor
        if !self.hidden {
            targetAlpha = self.alpha
            targetColor = previousColor
        }
        self.strokeColor = flashColor
        let hiddenWas = self.hidden
        self.hidden = false
        self._hiddenAfterAnimation = hiddenWas
        UIView.animateWithDuration(1,
            animations: {
                self.alpha = targetAlpha
                self.strokeColor = targetColor
            },
            completion: { completed in
                self.hidden = self._hiddenAfterAnimation
                self.strokeColor = previousColor
                self.alpha = previousAlpha
            }
        )
    }
    
    func animateStroke(callback:((StrokeView) -> ())? = nil) {
        self.hidden = false
        CATransaction.begin()
        let length = self.stroke.path.length()
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = CFTimeInterval(sqrt(sqrt(length/75)))
        animation.repeatCount = 1
        animation.fromValue = 0
        animation.toValue = 1
        let animationKey = "animateStroke\(arc4random())"
        if callback {
            CATransaction.setCompletionBlock() {callback!(self)}
        }
        _shapeLayer.addAnimation(animation, forKey: animationKey)
        CATransaction.commit()
        
    }
    
    func fadeOut(callback:() -> ()) {
        if !self.hidden {
            UIView.animateWithDuration(1, animations: {
                self.alpha = 0
            },
            completion: {completed in
                self.hidden = true
                self.alpha = 1
                callback()
            })
        }
    }
    
    var __transformedPath: UIBezierPath? = nil
    var _transformedPath: UIBezierPath {
        if !__transformedPath {
            __transformedPath = UIBezierPath(CGPath: stroke.path.CGPath)
            __transformedPath!.applyTransform(transformToView)
            __transformedPath!.lineWidth = lineWidth
            __transformedPath!.lineCapStyle = kCGLineCapRound
            __transformedPath!.lineJoinStyle = kCGLineJoinRound
        }
        return __transformedPath!
    }
    
    override var bounds: CGRect {
    didSet{
    __transformedPath = nil
    _shapeLayer.path = _transformedPath.CGPath
    }
    }
    
    var transformToView:CGAffineTransform {
    let width = self.bounds.width / stroke.bounds.width
    let height = self.bounds.height / stroke.bounds.height
    return CGAffineTransformMakeScale(width, height)
    }
    
    var transformFromView:CGAffineTransform {
    let width = stroke.bounds.width / self.bounds.width
    let height = stroke.bounds.height / self.bounds.height
    return CGAffineTransformMakeScale(width, height)
    }
}
