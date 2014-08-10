//
//  DrawQuizResult-Creation.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/12/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import CoreData

extension DrawQuizResult {
    
    class func add(character:Character, score:Float, iteration:Int, managedObjectContext context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("DrawQuizResult", inManagedObjectContext: context)
        let newResult: DrawQuizResult = DrawQuizResult(entity: entity, insertIntoManagedObjectContext: context)
        newResult.score = score
        newResult.character = String(character)
        newResult.date = NSDate()
        newResult.iteration = NSNumber(int: Int32(iteration)) 
        var error: NSError?
        context.save(&error)
        if error {
            NSLog("\(error)")
            assert(false, "Saving userDataManagedObject should succeed.")
        }
    }
    
    class func lastNResults(n: Int, ForCharacter character:Character, managedObjectContext context:NSManagedObjectContext) -> [DrawQuizResult] {
        let request = NSFetchRequest(entityName: "DrawQuizResult")
        request.predicate = NSPredicate(format: "character = %@", String(character))
        request.fetchLimit = n
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        var error:NSError?
        let results = context.executeFetchRequest(request, error:&error) as [DrawQuizResult]
        if error {
            NSLog("Failed to get last result for character: \(character)")
            NSLog("\(results)")
            NSLog("\(error)")
            NSLog("\(request.predicate)")
        }
        return results
    }
    
}