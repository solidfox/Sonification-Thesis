//
//  CharacterTestHistory.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/3/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

class CharacterQuizHistory {
    var _quizes: [CharacterDrawQuiz] = []
    var _currentIndex: Int = -1
    let _historySize: Int = 10
    
    var currentQuiz: CharacterDrawQuiz? {
        if !_quizes.isEmpty {
            return _quizes[_currentIndex]
        } else {
            return nil
        }
    }
    
    func addQuiz(quiz: CharacterDrawQuiz) {
        _quizes += quiz
        _purge()
    }
    
    func _purge() {
        while _currentIndex > _historySize {
            _quizes.removeAtIndex(0)
            _currentIndex--
        }
    }
    
    func nextQuiz() -> CharacterDrawQuiz? {
        var drawQuiz: CharacterDrawQuiz? = nil
        let nextIndex = _currentIndex + 1
        if nextIndex < _quizes.count {
            drawQuiz = _quizes[nextIndex]
            _currentIndex = nextIndex
        }
        return drawQuiz
    }
    
    func previousQuiz() -> CharacterDrawQuiz? {
        var drawQuiz: CharacterDrawQuiz? = nil
        let previousIndex = _currentIndex - 1
        if previousIndex >= 0 {
            drawQuiz = _quizes[previousIndex]
            _currentIndex = previousIndex
        }
        return drawQuiz
    }
    
    func quizBeforeQuiz(quiz: CharacterDrawQuiz) -> CharacterDrawQuiz? {
        var previousQuiz: CharacterDrawQuiz? = nil
        for historicQuiz in _quizes {
            if historicQuiz === quiz {
                break
            } else {
                previousQuiz = historicQuiz
            }
        }
        return previousQuiz
    }
    
    func quizAfterQuiz(quiz: CharacterDrawQuiz) -> CharacterDrawQuiz? {
        var nextQuiz: CharacterDrawQuiz? = nil
        var returnNext = false
        for historicQuiz in _quizes {
            if returnNext == true {
                nextQuiz = historicQuiz
                break
            }
            if historicQuiz === quiz {
                returnNext = true
            }
        }
        return nextQuiz
    }
}
