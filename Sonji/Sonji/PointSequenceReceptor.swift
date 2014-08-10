//
//  PointSequenceReceptor.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/4/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

protocol PointSequenceReceptor {
    func startSequenceAtPoint(point: CGPoint, inBounds: CGSize?)
    func addPointToSequence(point: CGPoint)
    func endSequence()
}