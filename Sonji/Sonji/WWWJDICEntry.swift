//
//  WWWJDIC.swift
//  KEX
//
//  Created by Daniel Schlaug on 6/10/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
//import DanielsKit

let _baseURL = "http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi?1ZMJ"
let _WWWJDICDownloadQueue = NSOperationQueue()

@objc class WWWJDICEntry {
    
    let character : Character
    let translations : [String]
    let kunReadings : [String]
    
    init(character: Character, translations: [String], kunReadings: [String]) {
        self.character = character
        self.translations = translations
        self.kunReadings = kunReadings
    }
    
    class func entryFromRawWWWJDICEntry(rawEntry:String) -> WWWJDICEntry? {
        var entry: WWWJDICEntry?
        
        //Parse rawEntry
        let fields : [String] = rawEntry.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var character : Character?
        var translations : [String] = []
        var kunReadings : [String] = []
        
        let fullRange = rawEntry.fullRange
        let nsEntry = rawEntry.bridgeToObjectiveC()
        
        (~/"\\p{Han}").enumerateMatchesInString(rawEntry, options: nil, range: fullRange){
            (result:NSTextCheckingResult!, flags:NSMatchingFlags, _:UnsafePointer<ObjCBool>) in
            character = rawEntry[0]
        }
        
        (~/"\\{(.+?)\\}").enumerateMatchesInString(rawEntry, options: nil, range: fullRange) {
            (result:NSTextCheckingResult!, flags:NSMatchingFlags, _:UnsafePointer<ObjCBool>) in
            translations += nsEntry.substringWithRange(result.rangeAtIndex(1))
        }
        
        (~/"\\p{Hiragana}+(\\.\\p{Hiragana}+)?").enumerateMatchesInString(rawEntry, options: nil, range: fullRange) {
            (result:NSTextCheckingResult!, flags:NSMatchingFlags, _:UnsafePointer<ObjCBool>) in
            kunReadings += nsEntry.substringWithRange(result.range)
        }
        
        if character {
            entry = WWWJDICEntry(character: character!, translations: translations, kunReadings: kunReadings)
        }
        
        return entry
    }
    
    class func entryFromRawWWWJDICResponse(response:String) -> WWWJDICEntry? {
        // Remove enclosing html
        let openingTag = response.rangeOfString("<pre>")
        let closingTag = response.rangeOfString("</pre>")
        var entryRange = Range(start: openingTag.endIndex, end: closingTag.startIndex)
        let rawEntry = response.substringWithRange(entryRange).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return entryFromRawWWWJDICEntry(rawEntry)
    }
    
    class func asyncDownloadEntryForCharacter(character: Character, withCallback callback: WWWJDICEntry? -> Void) {
        let operation = NSBlockOperation { callback(self.downloadEntryForCharacter(character)) }
        _WWWJDICDownloadQueue.addOperation(operation)
    }
    
    class func downloadEntryForCharacter(character: Character) -> WWWJDICEntry? {
        
        var entry: WWWJDICEntry?
        
        // Fetch database entry from internet
        var error : NSError?
        let urlString = _baseURL + character
        let url = NSURL.URLWithString(urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))
        let response = NSString.stringWithContentsOfURL(url, encoding: NSUTF8StringEncoding, error: &error)
        if error {
            println(error.description)
        } else {
            //Parse html
            entry = entryFromRawWWWJDICResponse(response)
        }
        
        return entry
    }
}