//
//  DrawQuizResult.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/12/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import CoreData

@objc(DrawQuizResult)
class DrawQuizResult: NSManagedObject {

    @NSManaged var character: String
    @NSManaged var date: NSDate
    @NSManaged var score: NSNumber
    @NSManaged var iteration: NSNumber

}
