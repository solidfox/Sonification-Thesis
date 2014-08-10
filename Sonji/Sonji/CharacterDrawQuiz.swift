//
//  CharacterDrawQuiz.swift
//  KEX
//
//  Created by Daniel Schlaug on 6/18/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import UIKit
//import KanjiVGKit
//import DanielsKit
//import BezierKit

protocol CharacterDrawQuizDelegate {
    //func characterDrawQuizDidCompleteRadical()
    func characterDrawQuizDidFinish(quiz:CharacterDrawQuiz)
}

class CharacterDrawQuiz {
    
    var delegate: CharacterDrawQuizDelegate?
    var _metadata: CharacterMetadata
    var _userStrokes: [UserStroke] = []
    
    var score: Float {return (_userStrokes.reduce(0.0){$0 + $1.score}) / Float(_userStrokes.count)}
    let iteration: Int
    let averagePointInTimeOfRecentTests: NSDate
    let recentAverageScore: Float?
    
    var hasAudio = true
    
    var done: Bool {return desiredStrokeIndex == nil}
    var lastStrokePassed: Bool = true
    var desiredStrokeIndex: Int? = 0
    var finishedStrokes: Int {return desiredStrokeIndex ? desiredStrokeIndex! : desiredStrokes.count}
    var desiredStrokes: [KVGStroke] {return _metadata.strokes}
    var desiredStroke: KVGStroke?   {return desiredStrokeIndex ? desiredStrokes[desiredStrokeIndex!] : nil}
    var translation:String          {return _metadata.translations.isEmpty ? "" : _metadata.translations[0]}
    var reading:String              {return _metadata.kunReadings.isEmpty ? "" :  _metadata.kunReadings[0]}
    var character:Character         {return _metadata.character}
    var strokeTries:Int             {return desiredStrokeIndex ? _userStrokes[desiredStrokeIndex!].tries : 0}
    
    var inputBounds: CGSize {
    willSet{
        if _userStrokes[0].bounds != newValue {
            for userStroke in _userStrokes {
                userStroke.bounds = inputBounds
            }
        }
    }
    }

    init(characterMetadata: CharacterMetadata, iteration:Int = 1, averagePointInTimeOfRecentTests:NSDate?, recentAverageScore:Float?, bounds: CGSize = CGSize(width: 320, height: 320)) {
        _metadata = characterMetadata
        self.iteration = iteration
        self.averagePointInTimeOfRecentTests = averagePointInTimeOfRecentTests ? averagePointInTimeOfRecentTests! : NSDate(timeIntervalSince1970: 0)
        self.recentAverageScore = recentAverageScore
        
        inputBounds = bounds
        _userStrokes = _metadata.strokes.map {UserStroke(refStroke: $0, bounds:self.inputBounds)}
        
        hasAudio = UserData.sharedInstance.hasAudio(_metadata.character)
    }
    
    func reset() {
        desiredStrokeIndex = 0
        _userStrokes = []
    }
    
    func userAskedForHelp() {
        if !done {
            _userStrokes[desiredStrokeIndex!].helps++
        }
    }
    
    func userStartedStrokeAtPoint(point:CGPoint, inBounds bounds:CGSize) {
        if !done {
            userMovedToPoint(point)
        }
    }
    
    func userMovedToPoint(point:CGPoint) {
        if !done {
            let userStroke = _userStrokes[desiredStrokeIndex!]
            userStroke.addPoint(point)
            // TODO Calculate and indicate intermediate score
        }
    }
    
    func userCompletedStrokeAtPoint(point:CGPoint) {
        if !done {
            userMovedToPoint(point)
            let userStroke = _userStrokes[desiredStrokeIndex!]
            if userStroke.passed {
                strokePassed(userStroke)
            } else {
                strokeFailed()
            }
        } else {
            assert(false, "This should not happen")
        }
    }
    
    func _quizDidFinish() {
        desiredStrokeIndex = nil
        
        let avgTries = Double(_userStrokes.reduce(0) {$0 + $1.tries}) / Double(_userStrokes.count)
        let avgHelps = Double(_userStrokes.reduce(0) {$0 + $1.helps}) / Double(_userStrokes.count)
        UserData.sharedInstance.addScoreForCharacter(_metadata.character, tries: avgTries, helps: avgHelps, iteration: iteration)
        
        delegate?.characterDrawQuizDidFinish(self)
    }
    
    func userCancelledStroke() {
        // WARNING unimplemented function placeholder
    }
    
    func strokePassed(stroke:UserStroke) {
        if !done {
            UserData.sharedInstance.addScoreForStroke(_metadata.character,
                userStroke:stroke
            )
            
            lastStrokePassed = true
            desiredStrokeIndex = desiredStrokeIndex! + 1
            if desiredStrokeIndex >= desiredStrokes.count {
                _quizDidFinish()
            }
        }
        
    }
    
    func strokeFailed() {
        lastStrokePassed = false
        if !done {
            _userStrokes[desiredStrokeIndex!].failed()
        } else {
            assert(false, "This should not happen")
        }
    }
    
}

