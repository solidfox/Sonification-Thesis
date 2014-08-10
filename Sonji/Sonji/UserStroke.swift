//
//  UserStroke.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/14/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import UIKit

class UserStroke {
    let _helpsWeight = 2
    var path: BezierPath = BezierPath()
    let refStroke: KVGStroke
    var _compareScore: Double?
    var compareScore: Double? {
    if !_compareScore {
        let score = self.path.compareTo(otherPath: refStroke.path, withInvariances: [.Scale, .Position])
        _compareScore = Double(score)
        }
        return _compareScore
    }
    var score:Float {return 1.0/Float(tries+helps*_helpsWeight)}
    var tries = 1
    var helps = 0
    var bounds: CGSize {
    willSet{
        if !path.empty {
            let oldValue = bounds
            let sx = newValue.width / oldValue.width
            let sy = newValue.height / oldValue.height
            let transform = CGAffineTransformMakeScale(sx, sy)
            self.path.applyTransform(transform)
        }
        _transformToRefDim = nil
    }
    }
    
    var _transformToRefDim:CGAffineTransform?
    var transformToRefDim: CGAffineTransform {
    if !_transformToRefDim {
        _transformToRefDim = CGAffineTransformMakeScale(
            refStroke.bounds.width/bounds.width,
            refStroke.bounds.height/bounds.height)
        }
        return _transformToRefDim!
    }
    
    var passed: Bool {
        let reqAccuracy = 0.2*refStroke.bounds.width
        let startingPointOffset = distance(CGPointApplyAffineTransform(path.firstPoint, transformToRefDim), refStroke.path.firstPoint)
        let startingPointOK = startingPointOffset <= reqAccuracy
        let endPointOffset = distance(CGPointApplyAffineTransform(path.currentPoint, transformToRefDim), refStroke.path.currentPoint)
        let endPointOK = endPointOffset <= reqAccuracy
        return compareScore > Double(requiredScore) && startingPointOK && endPointOK
    }
    
    init(refStroke: KVGStroke, bounds:CGSize) {
        self.bounds = bounds
        self.refStroke = refStroke
    }
    
    func addPoint(point:CGPoint) {
        if path.empty {
            path.add(.MoveToPoint(point))
        } else {
            path.add(.LineToPoint(point))
        }
        _compareScore = nil
    }
    
    func failed() {
        path = BezierPath()
        ++tries
    }
    
    var requiredScore: CGFloat {
    switch refStroke.type {
    case "㇕", "㇆": return 0.71
    case "㇔": return 0.55
    default: return 0.81
        }
    }
}