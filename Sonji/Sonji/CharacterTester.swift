//
//  CharacterTester.swift
//  KEX
//
//  Created by Daniel Schlaug on 6/18/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
//import DanielsKit
import CoreData

class CharacterTester: CharacterMetadataRepositoryDelegate, CharacterDrawQuizDelegate {
    
    let _charactersToTest: [Character]
    var _quizHistory = CharacterQuizHistory()
    var _completionHandlers: [(Character, (CharacterDrawQuiz) -> Void)] = []
    var _userDataOperations: [(() -> ())] = []
    var _metadataForCharacter: Dictionary<Character, CharacterMetadata> = [:]
    let _metadataRepo: CharacterMetadataRepository! = nil
    var _userDataContext: NSManagedObjectContext!
    var _userDataContextSemaphore = dispatch_semaphore_create(0)
    
    #if DEBUG
    let _longRetentionTime = NSTimeInterval(5*60)
    #else
    let _longRetentionTime = NSTimeInterval(8*60*60)
    #endif
    
    var _mostUrgentCharacter: Character {
        if !_userDataContext {
            dispatch_semaphore_wait(_userDataContextSemaphore, 20*NSEC_PER_SEC)
        }
        let lastChar = _quizHistory.currentQuiz?.character
        let candidates = lastChar ? self._charactersToTest.filter{$0 != lastChar!} : self._charactersToTest
        let nResults = 3
            var recentResults = candidates.map {character -> (Character, Float, NSDate) in
            let fourResults = DrawQuizResult.lastNResults(nResults, ForCharacter: character, managedObjectContext: self._userDataContext!)
            let averageScore = self.averageScoreForResults(fourResults)
            let averageTimePoint = self.averageTimePointForResults(fourResults, requiredResults:nResults)
            return (character, averageScore, averageTimePoint)
        }
        
        recentResults.sort {return $0.1 < $1.1}
        if recentResults[0].1 >= 0.83 {  // WARNING Dirty magic number
            recentResults.sort {return $0.2.timeIntervalSinceNow < $1.2.timeIntervalSinceNow}
        }
        
        let distribution = [0.40, 0.35, 0.15, 0.06, 0.03, 0.02, 0.02, 0.02]
            
        var characterToLoad = recentResults[randomIndexFromDistribution(distribution)].0
            
//        NSLog("\(recentResults)")
        return characterToLoad
    }
    
    var timeForNextQuiz: NSDate {
        let timeForNextQuizIsNow = NSDate(timeIntervalSince1970: 0)
    
        if UserData.sharedInstance.surveyIsOver {return timeForNextQuizIsNow}
        
        let desiredIterations = 3
        if !_userDataContext {
            dispatch_semaphore_wait(_userDataContextSemaphore, 20*NSEC_PER_SEC)
        }
        var earliestDate = NSDate()
        for char in _charactersToTest {
            let results = DrawQuizResult.lastNResults(desiredIterations, ForCharacter: char, managedObjectContext: self._userDataContext)
            if results.count == desiredIterations {
                earliestDate = results[desiredIterations-1].date.earlierDate(earliestDate)
            } else {
                earliestDate = NSDate(timeIntervalSince1970: 0)
                break
            }
        }
        let theTime = earliestDate.dateByAddingTimeInterval(_longRetentionTime)
        return theTime
    }
    
    
    init() {
        if !UserData.sharedInstance.surveyIsOver {
            _charactersToTest = ["土","日","囗","甲","上","木","大","天","下","雨"]
        } else {
            _charactersToTest = ["土","日","囗","甲","上","木","大","天","下","雨", "困", "人", "果", "音", "立", "男", "田", "森", "林"]
        }
        
        UserData.sharedInstance.loadManagedObjectContext {loadedContext in
            self._userDataContext = loadedContext
            dispatch_semaphore_signal(self._userDataContextSemaphore)
            while !self._userDataOperations.isEmpty {
                let op = self._userDataOperations.removeAtIndex(0)
                op()
            }
        }
        _metadataRepo = CharacterMetadataRepository(delegate:self)
        for character in _charactersToTest {
            _metadataRepo.loadCharacterMetadataFor(character)
        }
    }
    
    func _addLoadCompletionHandler(handler:((CharacterDrawQuiz) -> Void), forCharacter character: Character) {
        _completionHandlers += (character, handler)
    }
    
    func _addUserDataOperation(operation: () -> ()) {
        if _userDataContext {
            assert(_userDataOperations.count == 0, "There should not be any operations at this point.")
            operation()
        } else {
            _userDataOperations += operation
        }
    }
    
    func _characterIsReady(character: Character) -> Bool {
        return _metadataForCharacter[character] ? true : false
    }
    
    func _loadedNewCharacter(character: Character) {
        if let metadata = _metadataForCharacter[character] {
            for (index, (characterForHandler, handler)) in enumerate(_completionHandlers) {
                if character == characterForHandler {
                    // REMOVE the handler
                    _completionHandlers.removeAtIndex(index)
                    // CALL the handler
                    _addUserDataOperation {
                        // Create and add the newQuiz
                        let nResultsAverage = 4
                        let fourResults = DrawQuizResult.lastNResults(nResultsAverage, ForCharacter: metadata.character, managedObjectContext: self._userDataContext!)
                        let lastResult:DrawQuizResult? = fourResults.isEmpty ? nil : fourResults[0]
                        let iteration = lastResult ? lastResult!.iteration.integerValue + 1 : 1
                        let averageTimePoint = self.averageTimePointForResults(fourResults, requiredResults: nResultsAverage)
                        let averageScore = self.averageScoreForResults(fourResults)
//                        NSLog("Iteration at quiz creation \(iteration)")
                        let newQuiz = CharacterDrawQuiz(characterMetadata: metadata,
                            iteration: iteration,
                            averagePointInTimeOfRecentTests: averageTimePoint,
                            recentAverageScore: averageScore)
                        newQuiz.delegate = self
                        self._quizHistory.addQuiz(newQuiz)
                        
                        self.loadNextQuiz(handler)
                    }
                }
            }
        } else {
            NSLog("_loadedNewCharacter failed for character: \(character)")
            fatalError("_loadedNewCharacter was called without metadata being loaded")
        }
    }
    
    // MARK - Quiz flow control
    
    func loadNextQuiz(completionHandler: ((CharacterDrawQuiz) -> Void)) {
        if let nextTest = _quizHistory.nextQuiz() {
            completionHandler(nextTest)
        } else {
            let characterToLoad = _mostUrgentCharacter
            self._addLoadCompletionHandler(completionHandler, forCharacter: characterToLoad)
            if self._characterIsReady(characterToLoad) {
                self._loadedNewCharacter(characterToLoad)
            }
        }
    }
    
    func averageScoreForResults(results:[DrawQuizResult]) -> Float {
        var averageScore:Float = 0.7
        if results.count > 0 {
        averageScore = results.reduce(0.0) {$0 + $1.score.floatValue} / Float(results.count)
        }
        return averageScore
    }
    func averageTimePointForResults(results:[DrawQuizResult], requiredResults nResults:Int) -> NSDate {
        var averageTimePoint = NSDate(timeIntervalSince1970: 0)
        if results.count >= nResults {
            let averageTimeInterval = results.reduce(0.0) {$0 + $1.date.timeIntervalSinceNow} / Double(results.count)
            averageTimePoint = NSDate(timeIntervalSinceNow: averageTimeInterval)
        }
        return averageTimePoint
    }
    
    func previousQuiz() -> CharacterDrawQuiz? {
        return _quizHistory.previousQuiz()
    }
    
    func quizBeforeQuiz(quiz: CharacterDrawQuiz) -> CharacterDrawQuiz? {
        return _quizHistory.quizBeforeQuiz(quiz)
    }
    
    func quizAfterQuiz(quiz: CharacterDrawQuiz, completionHandler: ((CharacterDrawQuiz) -> Void)) {
        if let existingQuiz = _quizHistory.quizAfterQuiz(quiz) {
            completionHandler(existingQuiz)
        } else {
            loadNextQuiz(completionHandler)
        }
    }
    
    func skipToRelativeIndex(index: Int) {
        if index == 0 {
            return
        } else if index > 0 {
            for i in 1...index {
                loadNextQuiz() {quiz in }
            }
        } else {
            for i in -1...index {
                previousQuiz()
            }
        }
    }
    
    // MARK - CharacterMetadataRepository Delegate functions
    
    func _characterMetadataRepository(repository: CharacterMetadataRepository, didFinishLoadingMetadata metadata: CharacterMetadata, forCharacter character: Character) {
        _metadataForCharacter[character] = metadata
        _loadedNewCharacter(character)
    }
    
    func _characterMetadataRepository(repository: CharacterMetadataRepository, didFailLoadingMetadataForCharacter character: Character, withError error: NSError!) {
        #if DEBUG
        if error {
            NSLog("\(error)")
        }
        NSLog("Retrying...")
        #endif
        _metadataRepo.loadCharacterMetadataFor(character)
    }

    // MARK - CharacterMetadataRepository Delegate functions
    
    func characterDrawQuizDidFinish(quiz:CharacterDrawQuiz) {
        _addUserDataOperation {
            DrawQuizResult.add(quiz.character,
                score: quiz.score,
                iteration:quiz.iteration,
                managedObjectContext: self._userDataContext!)
        }
    }
    
    
    
}
