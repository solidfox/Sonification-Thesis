//
//  UserData.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/10/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class UserData {
    class var sharedInstance: UserData {
        struct Singleton {
            static let instance = UserData()
        }
        if Singleton.instance.surveyIsOver {
            Singleton.instance.audioOverride = true
        }
        return Singleton.instance
    }
    
    let _sessionsKey = "timesWaitedKey"
    
    var _managedDocument: UIManagedDocument?
    func loadManagedObjectContext(completion:(NSManagedObjectContext?) -> ()) {
        if !_managedDocument {
            let semaphore = dispatch_semaphore_create(0)
            let fileManager = NSFileManager.defaultManager()
            let documentDirectory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
            let documentName = "UserData"
            let url = documentDirectory.URLByAppendingPathComponent(documentName)
            _managedDocument = UIManagedDocument(fileURL: url)
            let fileExists = fileManager.fileExistsAtPath(url.path)
            if fileExists {
                _managedDocument!.openWithCompletionHandler {success in
                    completion(success ? self._managedDocument!.managedObjectContext : nil)
                }
            } else {
                _managedDocument!.saveToURL(url, forSaveOperation: .ForCreating) {success in
                    completion(success ? self._managedDocument!.managedObjectContext : nil)
                }
            }
        }
        completion(_managedDocument?.managedObjectContext)
    }
    
    var audioOverride = false
    
    var userLastClued: NSDate {
    get {
        var userLastClued = NSDate(timeIntervalSince1970: 0)
        var lastDateData: AnyObject! = NSUserDefaults.standardUserDefaults().objectForKey("userLastClued")
        if let lastDate = lastDateData as? NSDate {
            userLastClued = lastDate
        }
        return userLastClued
    }
    set {
        NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "userLastClued")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    }
    
    #if DEBUG
    var surveyIsOver:Bool {return true}
    #else
    var surveyIsOver: Bool {return nSessions > 2}
    #endif
    var nSessions: Int {return NSUserDefaults.standardUserDefaults().integerForKey(_sessionsKey)}
    func incrementSessions() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let oldValue = defaults.integerForKey(_sessionsKey)
        defaults.setValue(oldValue + 1, forKey: _sessionsKey)
    }
    
    func hasBeenIntroduced(character:Character) -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        var hasBeenIntroduced = defaults.boolForKey("\(character)HasBeenIntroduced")
        if !hasBeenIntroduced {
            defaults.setBool(true, forKey: "\(character)HasBeenIntroduced")
        }
        return hasBeenIntroduced
    }
    
    
    func hasAudio(character:Character) -> Bool {
        if audioOverride {return true}
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var audioDisabled = defaults.integerForKey("audioDisabledFor\(character)")
        if audioDisabled == 0 {
            audioDisabled = Int(arc4random_uniform(2)) == 0 ? -1 : 1
            defaults.setInteger(audioDisabled, forKey: "audioDisabledFor\(character)")
            defaults.synchronize()
        }
        switch audioDisabled {
        case -1:    return false
        case 1:     return true
        default:    assert(false, "This shouldn't happen.")
        }
        assert(false, "This shouldn't happen.")
        return true
    }

    func addScoreForCharacter(character:Character, tries:Double, helps:Double, iteration:Int) {
        _sendCharacterFormData(character, tries:tries, helps:helps, iteration:iteration)
    }
    
    func addScoreForStroke(character:Character, userStroke:UserStroke) {
        _sendStrokeFormData(character, userStroke:userStroke)
    }
    
    func _sendCharacterFormData(character:Character, tries:Double, helps:Double, iteration:Int) {
        
        if surveyIsOver {return}
        
        
        let request = NSMutableURLRequest(URL:
            NSURL(string: "https://docs.google.com/forms/d/1tokSvOkI4VUcAozkMVHtfLh2UUYtJWbjr6bTi_lDv5A/formResponse"))
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        
        
        let fields = [
            /*idField*/ "entry.944012104=\(deviceID)",
            /*charField*/ "entry.95271698=\(character)",
            /*triesField*/ "entry.1306028203=\(tries)",
            /*helpsField*/ "entry.671588596=\(helps)",
            /*timeField*/ "entry.1382186980=\(NSDate().description)",
            /*audioField*/ "entry.1472491562=\(hasAudio(character))",
            /*iterationField*/ "entry.1521849499=\(iteration)",
            /*sessionField*/ "entry.1688688554=\(nSessions)"
        ]
        var postString = fields.implode("&")!
        postString = postString.bridgeToObjectiveC().stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let data = postString.bridgeToObjectiveC().dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = data
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        NSURLConnection.connectionWithRequest(request, delegate: self)
    }
    
    var deviceID:String {
        #if DEBUG
            return "DEBUG" + UIDevice.currentDevice().identifierForVendor.UUIDString
        #else
            return UIDevice.currentDevice().identifierForVendor.UUIDString
        #endif
    }
    
    func _sendStrokeFormData(character:Character, userStroke stroke:UserStroke) {
        
        if surveyIsOver {return}
        
        let request = NSMutableURLRequest(URL:
            NSURL(string: "https://docs.google.com/forms/d/1Rm-KUwbkkkkFpqzZNBmWKLmz4u9B1eEM2Db3__WTK90/formResponse"))
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        
        let fields = [
            /*idField*/ "entry.1936373542=\(deviceID)",
            /*charField*/ "entry.2080157276=\(character)",
            /*strokeIndex*/ "entry.44505072=\(stroke.refStroke.strokeOrder)",
            /*strokeType*/ "entry.2109753993=\(stroke.refStroke.type)",
            /*triesField*/ "entry.1095176755=\(stroke.tries)",
            /*helpsField*/ "entry_714182263=\(stroke.helps)",
            /*timeField*/ "entry.446943211=\(NSDate().description)",
            /*audioField*/ "entry.2046317849=\(hasAudio(character))",
            /*compareField*/ "entry.1135236273=\(stroke.compareScore)",
            /*startEndField*/ "entry.266771474=\(stroke.refStroke.path.firstPoint) - \(stroke.refStroke.path.currentPoint)",
            /*sessionsField*/ "entry.922383067=\(nSessions)"
        ]
        var postString = fields.implode("&")!
        postString = postString.bridgeToObjectiveC().stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let data = postString.bridgeToObjectiveC().dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = data
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        NSURLConnection.connectionWithRequest(request, delegate: self)
    }
    
    func sendComment(comment:String) {
        
        let request = NSMutableURLRequest(URL:
            NSURL(string: "https://docs.google.com/forms/d/1VR1xg2oFGsFLbtiRukC2zExF7kkr-A4aP7_5blq9g_M/formResponse"))
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        
        
        let idField = "entry.1844307797=\(deviceID)"
        let commentField = "entry.1746965540=\(comment)"
        var postString = [idField, commentField].implode("&")!
        postString = postString.bridgeToObjectiveC().stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let data = postString.bridgeToObjectiveC().dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = data
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        NSURLConnection.connectionWithRequest(request, delegate: self)
    }
}
