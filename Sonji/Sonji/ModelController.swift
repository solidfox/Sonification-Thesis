//
//  ModelController.swift
//  Sonji
//
//  Created by Daniel Schlaug on 6/29/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements cardSetViewController:viewControllerBeforeViewController: and cardSetViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */

class ModelController: NSObject, CardSetViewControllerDataSource, UIAlertViewDelegate {
    
    let _characterTester = CharacterTester()
    let _storyboard: UIStoryboard
    var _thankYouAlert: UIAlertView?
    var _previousExperienceAlert: UIAlertView?
    
    let approximateQuizTime: NSTimeInterval = 30*60 // WARNING
    
    func firstViewController() -> UIViewController {
        return next()!
    }
    
    func completedSession(nextSession:NSDate) {
        UserData.sharedInstance.incrementSessions()
        
        if UserData.sharedInstance.nSessions == 1 {
            _previousExperienceAlert = UIAlertView(title: "Previous experience",
                message: "Did you previously know how to write these characters?",
                delegate: self, cancelButtonTitle: nil, otherButtonTitles: "Yes! Knew them all!", "Yes, some of them", "Nope, all new to me")
            _previousExperienceAlert?.show()
        }
        
        setReminderNotificationAtEarliestDate(nextSession)
    }
    
    func setReminderNotificationAtEarliestDate(earliestDate:NSDate) {
        var notificationDate:NSDate = earliestDate
        let cal:NSCalendar = NSCalendar.currentCalendar()
        let hour = cal.components(.CalendarUnitHour, fromDate: earliestDate).hour
        if hour < 11 {
            notificationDate = earliestDate.dateByAddingTimeInterval(NSTimeInterval(60*60*(11-hour)))
        } else if hour > 21 {
            notificationDate = earliestDate.dateByAddingTimeInterval(NSTimeInterval(60*60*(11+hour)))
        }
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        let notice = UILocalNotification()
        notice.alertBody = "Let's continue the experiment! Time to learn!"
        notice.alertAction = "Open Sonji"
        notice.fireDate = notificationDate
        notice.soundName = "notice.m4a"
        UIApplication.sharedApplication().scheduleLocalNotification(notice)
    }
    
    func _instantiateDrawQuizViewController() -> CharacterDrawQuizViewController {
        let nextViewController = _storyboard.instantiateViewControllerWithIdentifier("CharacterDrawQuizViewController") as CharacterDrawQuizViewController
        var dummy = nextViewController.view
        return nextViewController
    }
    
    func _instantiatePleaseWaitViewController() -> PleaseWaitViewController {
        let pleaseWaitController = _storyboard.instantiateViewControllerWithIdentifier("PleaseWaitViewController") as PleaseWaitViewController
        var dummy = pleaseWaitController.view
        return pleaseWaitController
    }
    
    init(storyboard: UIStoryboard) {
        self._storyboard = storyboard
        if UserData.sharedInstance.surveyIsOver {
            approximateQuizTime = 0
        }
    }
    
    var shouldDoQuiz:Bool {
        if UserData.sharedInstance.surveyIsOver {
            
            let thankedKey = "userHasBeenThanked"
            if !NSUserDefaults.standardUserDefaults().boolForKey(thankedKey) {
                _thankYouAlert = UIAlertView(title: "Thank you",
                    message: "The experiment is now over and all limitations have been removed. In conclusion, how strict did you feel I was in accepting your writing?",
                    delegate: self, cancelButtonTitle: nil,
                    otherButtonTitles: "Too kind", "Just good", "Too strict", "Don't know")
                _thankYouAlert!.show()
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: thankedKey)
            }
            
            return true
        }
            
        let timeForNextQuizHasPassed = _characterTester.timeForNextQuiz.compare(NSDate()) == NSComparisonResult.OrderedAscending
    
        if timeForNextQuizHasPassed {
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            return true
        } else {return false}
    }
    
    func next(previous:UIViewController? = nil) -> UIViewController? {
        if shouldDoQuiz {
            let newC = _instantiateDrawQuizViewController()
            _characterTester.loadNextQuiz() {nextQuiz in newC.characterDrawQuiz = nextQuiz}
            return newC
        } else {
            if previous as? PleaseWaitViewController {
                return nil
            } else {
                let targetTime = _characterTester.timeForNextQuiz.dateByAddingTimeInterval(approximateQuizTime)
                
                completedSession(targetTime)
                
                let newC = _instantiatePleaseWaitViewController()
                newC.waitUntilTime = targetTime
                return newC
            }
        }
    }
    
    // #pragma mark - Page View Controller Data Source
    
    func cardSetViewController(cardSetViewController: CardSetViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var previousViewController: CharacterDrawQuizViewController? = nil
        if let characterDrawQuizViewController = viewController as? CharacterDrawQuizViewController {
            if let quiz = characterDrawQuizViewController.characterDrawQuiz {
                if let previousQuiz = _characterTester.quizBeforeQuiz(quiz) {
                    previousViewController = _instantiateDrawQuizViewController()
                    previousViewController!.characterDrawQuiz = previousQuiz
                }
            }
        }
        return previousViewController
    }

    func cardSetViewController(cardSetViewController: CardSetViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var nextViewController: UIViewController? = nil
        
        if let characterDrawQuizViewController = viewController as? CharacterDrawQuizViewController {
            if let quiz = characterDrawQuizViewController.characterDrawQuiz {
                if shouldDoQuiz {
                    let newController = _instantiateDrawQuizViewController()
                    nextViewController = newController
                    _characterTester.quizAfterQuiz(quiz) {
                        nextQuiz in newController.characterDrawQuiz = nextQuiz
                    }
                } else {
                    let newC = _instantiatePleaseWaitViewController()
                    let targetTime = _characterTester.timeForNextQuiz.dateByAddingTimeInterval(approximateQuizTime)
                    newC.waitUntilTime = targetTime
                    completedSession(targetTime)
                    nextViewController = newC
                }
            }
        } else {
            nextViewController = next(previous: viewController)
        }
        return nextViewController
    }

    
    // MARK - UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.numberOfButtons > 1 {
            var comment = alertView.buttonTitleAtIndex(buttonIndex)
            UserData.sharedInstance.sendComment(comment)
        }
        if alertView == _thankYouAlert {
            let explainAlert = UIAlertView(title: "An explanation", message: "So why did only some characters have sounds? This was randomized so I could compare how quickly you learned those with and without sound. You will now hear all sounds and you can tap the weird reading to hear it pronounced.", delegate: nil, cancelButtonTitle: "Cool!")
        }
    }
}

