//
//  PointSequenceView.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/11/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit
import QuartzCore

class PointSequenceView: UIView, PointSequenceReceptor {
    var pointColor = UIColor.purpleColor()
    var pointSize: CGFloat = 5
    
    var interpolatePoints:Bool = false
    var lineColor = UIColor.blackColor()
    var lineWidth:CGFloat = 5
    var _linePathStarted = false
    var _linePath:CGMutablePath? = nil
    var __lineShape: CAShapeLayer! = nil
    var _lineShape: CAShapeLayer! {
    get{
        if !__lineShape {
            __lineShape = CAShapeLayer()
            __lineShape.lineCap = kCALineCapRound
            __lineShape.lineJoin = kCALineJoinRound
            __lineShape.lineWidth = lineWidth
            __lineShape.strokeColor = lineColor.CGColor
            __lineShape.fillColor = UIColor.clearColor().CGColor
            _linePath = CGPathCreateMutable()
            __lineShape.path = _linePath
        }
        layer.addSublayer(__lineShape)
        return __lineShape
    }
    set {
        __lineShape = newValue
    }
    }
    
    var pointsFadeAway = false
    var fadeDuration: Double = 0.7
    
    var shapeLayer:CAShapeLayer = CAShapeLayer()
    
    var _pointLayers:[CAShapeLayer] = []
    
    func startSequenceAtPoint(point: CGPoint, inBounds: CGSize?) {
        addPointToSequence(point)
    }
    
    func addPointToSequence(point: CGPoint) {
        var shape = CAShapeLayer()
        shape.path =  UIBezierPath(arcCenter: CGPointZero, radius: pointSize/2, startAngle: 0, endAngle: 7, clockwise: true).CGPath
        shape.fillColor = pointColor.CGColor
        shape.position = point
        
        _pointLayers += shape
        
        self.layer.addSublayer(shape)
        
        if interpolatePoints {
            let lineShape = _lineShape
            if !_linePathStarted {
                CGPathMoveToPoint(_linePath, nil, point.x, point.y)
                _linePathStarted = true
            } else {
                CGPathAddLineToPoint(_linePath, nil, point.x, point.y)
            }
            lineShape.didChangeValueForKey("path")
        }
        
        if pointsFadeAway {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.duration = fadeDuration
            animation.fromValue = 0
            animation.toValue = 1
            shape.addAnimation(animation, forKey: "fadeAway")
        }
        self.setNeedsDisplay()
    }
    
    func clear() {
        _lineShape.removeFromSuperlayer()
        for pointLayer in _pointLayers {pointLayer.removeFromSuperlayer()}
        _pointLayers = []
        _lineShape = nil
        _linePathStarted = false
    }
    
    func endSequence() {
        _linePathStarted = false
    }
}
