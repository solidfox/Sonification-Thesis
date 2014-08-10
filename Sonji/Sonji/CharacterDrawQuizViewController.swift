//
//  CharacterDrawQuizViewController.swift
//  Sonji
//
//  Created by Daniel Schlaug on 6/29/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit
//import KanjiVGKit
import AVFoundation

class CharacterDrawQuizViewController: UIViewController, UIGestureRecognizerDelegate, UIAlertViewDelegate {
    
    // Views
    @IBOutlet var metaDataView: UIView
    @IBOutlet var translationLabel: UILabel
    @IBOutlet var desiredCharacterView: CharacterView
    @IBOutlet var loadingIndicator: UIActivityIndicatorView
    var canvas:CharacterCanvas!
    var strokeSonifier:StrokeSonifier?
    var mnemonicSoundPlayer:MnemonicSoundPlayer?
    @IBOutlet var nextArrowLabel: UILabel
    
    let siri = AVSpeechSynthesizer()
    
    // Briefing dialogs
    let userHasBeenBriefedKey = "userHasBeenBriefed"
    var welcome: UIAlertView?
    var yourTurn: UIAlertView?
    @IBOutlet var canvasHelp: UILabel
    
    // GestureRecognizers
    var drawRecognizer: UIPanGestureRecognizer!
    var characterTapRecognizer: UITapGestureRecognizer!
    var canvasActive:Bool {
    set {
        if newValue == true {
            self.canvas.hidden = false
        } else {
            self.canvas.hidden = true
        }
    }
    get {
        return !self.canvas.hidden
    }
    }
    
    // Models
    var characterDrawQuiz: CharacterDrawQuiz? {
    willSet{
        if characterDrawQuiz {
            NSLog("old \(characterDrawQuiz?.character)")
            NSLog("new \(newValue?.character)")
            let debugOldV = characterDrawQuiz
            let debugNewV = newValue
            assert(false, "characterDrawQuiz should only be set once.")
        }
    }
    didSet {
        canvasActive = false
        if let characterDrawQuiz = self.characterDrawQuiz {
            self.desiredCharacterView.shownStrokes = 0..<0
            self.desiredCharacterView.strokes = characterDrawQuiz.desiredStrokes
            self.translationLabel.text = "\(characterDrawQuiz.translation)\n\(characterDrawQuiz.reading)"
            if characterDrawQuiz.hasAudio {
                self.mnemonicSoundPlayer = MnemonicSoundPlayer(word: characterDrawQuiz.translation)
            }
            loadingIndicator.stopAnimating()
            
            quizInitializationCheck()
        }
    }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        canvas.frame = desiredCharacterView.frame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up Views
        canvas = CharacterCanvas(frame: desiredCharacterView.frame)
        canvas.lineColor = UIColor.purpleColor()
        canvas.pointColor = UIColor.clearColor()
        self.view.addSubview(canvas)
        
        
        // Set up Gesture Recognizers
        drawRecognizer = UIPanGestureRecognizer(target: self, action: "characterPanGesture:")
        drawRecognizer.delegate = self
        drawRecognizer.delaysTouchesBegan = false
        drawRecognizer.delaysTouchesEnded = false
        canvas.addGestureRecognizer(drawRecognizer)
        
        characterTapRecognizer = UITapGestureRecognizer(target: self, action: "characterTapGesture:")
        characterTapRecognizer.delegate = self
        canvas.addGestureRecognizer(characterTapRecognizer)
        
        let readingTapRecognizer = UITapGestureRecognizer(target: self, action: "readingTapGesture:")
        metaDataView.addGestureRecognizer(readingTapRecognizer)
    }
    
    // MARK - Flow control functions
    
    func quizInitializationCheck() {
        if let characterDrawQuiz = characterDrawQuiz {
            if UserData.sharedInstance.hasBeenIntroduced(characterDrawQuiz.character) {
                beginQuiz()
            } else {
                let userHasBeenBriefed = NSUserDefaults.standardUserDefaults().boolForKey(userHasBeenBriefedKey)
                if userHasBeenBriefed {
                    introduceCharacter() {
                        self.beginQuiz()
                    }
                } else {
                    showBriefing()
                }
            }
        }
    }
    
    func showBriefing() {
        welcome = UIAlertView(title: "Welcome", message: "This here below is your canvas where you will be learning thousand year old characters.", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "Ok")
        welcome!.show()
    }
    
    func introduceCharacter(callback: () -> ()) {
        assert(characterDrawQuiz, "introduceCharacter should not be called when no characterDrawQuiz is present")
        if let characterDrawQuiz = self.characterDrawQuiz {
            desiredCharacterView.animateDrawingCharacter() {
                callback()
            }
        }
    }
    
    func beginQuiz() {
        self.canvasActive = true
        self._prepareNextStroke()
    }
    
    func clueUser() {
        if let characterDrawQuiz = characterDrawQuiz {
            if characterDrawQuiz.strokeTries > 3 &&
                (UserData.sharedInstance.userLastClued.timeIntervalSinceNow < -6 * 60 * 60) {
                    canvasHelp.text = "Tap for a clue"
                    _flashCanvasHelp()
                    UserData.sharedInstance.userLastClued = NSDate()
            }
        }
    }
    
    func _flashCanvasHelp() {
        UIView.animateWithDuration(1.0,
            delay: 0.0, options:UIViewAnimationOptions.CurveEaseOut,
            animations: {
                self.canvasHelp.alpha = 1
            },
            completion: {completed in
                UIView.animateWithDuration(1.0,
                    delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn | UIViewAnimationOptions.BeginFromCurrentState,
                    animations: {
                        self.canvasHelp.alpha = 0
                    }, completion: {_ in
                        
                    }
                )
            }
        )
    }
    
    func _prepareNextStroke() {
        assert(characterDrawQuiz, "_prepareNextStroke should not be called when no characterDrawQuiz is present")
        if let characterDrawQuiz = self.characterDrawQuiz {
            self.desiredCharacterView.shownStrokes = 0..<(characterDrawQuiz.finishedStrokes)
            if !characterDrawQuiz.done {
                if characterDrawQuiz.hasAudio {
                    self.strokeSonifier = StrokeSonifier(referenceStroke: characterDrawQuiz.desiredStroke!)
                }
            } else {
                self.finished()
            }
        }
    }
    
    func reset() {
        self.characterDrawQuiz?.reset()
        self._prepareNextStroke()
    }
    
    func finished() {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC))
        dispatch_after(delay, dispatch_get_main_queue()) {
            self.nextArrowLabel.alpha = 0
            self.nextArrowLabel.hidden = false
            UIView.animateWithDuration(2){
                self.nextArrowLabel.alpha = 1
            }
        }
    }
    
    func goToNextQuiz() {
        (parentViewController as? CardSetViewController)?.displayNext()
        mnemonicSoundPlayer?.stop()
        mnemonicSoundPlayer = nil
    }
    
    // MARK - Gesture reactions
    
    func characterTapGesture(sender: UITapGestureRecognizer) {
        if let characterDrawQuiz = characterDrawQuiz {
            
            if sender.state == .Ended {
                
                if characterDrawQuiz.done {
                    goToNextQuiz()
                } else {
                    characterDrawQuiz.userAskedForHelp()
                    desiredCharacterView.flashStrokeWithIndex(characterDrawQuiz.desiredStrokeIndex!)
                }
                
            }
            
        }
    }
    
    func readingTapGesture(sender: UITapGestureRecognizer) {
        if let characterDrawQuiz = characterDrawQuiz {
            
            if sender.state == .Ended {
                
                if UserData.sharedInstance.surveyIsOver {
                    let utterance = AVSpeechUtterance(string: characterDrawQuiz.reading)
                    utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
                    utterance.rate = 0.1
                    siri.speakUtterance(utterance)
                }
                
            }
            
        }
    }
    
    func characterPanGesture(sender: UIPanGestureRecognizer) {
        if let characterDrawQuiz = characterDrawQuiz {
            if !characterDrawQuiz.done {
                var point = sender.locationInView(desiredCharacterView)
                var velocity = sender.velocityInView(desiredCharacterView)
                
                switch sender.state {
                case .Began:
                    characterDrawQuiz.userStartedStrokeAtPoint(point, inBounds: desiredCharacterView.bounds.size)
                    strokeSonifier?.startSequenceAtPoint(point, inBounds: desiredCharacterView.bounds.size)
                    canvas.startSequenceAtPoint(point, inBounds: canvas.bounds.size)
                case .Changed:
                    characterDrawQuiz.userMovedToPoint(point)
                    strokeSonifier?.addPointToSequence(point)
                    canvas.addPointToSequence(point)
                case .Ended:
                    characterDrawQuiz.userCompletedStrokeAtPoint(point)
                    strokeSonifier?.endSequence()
                    if characterDrawQuiz.lastStrokePassed {
                        canvas.animateSuccess()
                        _prepareNextStroke()
                    } else {
                        canvas.animateFailure()
                        clueUser()
                    }
                case .Cancelled:
                    characterDrawQuiz.userCancelledStroke()
                    strokeSonifier?.endSequence()
                case .Failed, .Possible:
                    // Ignored
                    break
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if alertView == welcome? {
            introduceCharacter() {
                self.yourTurn = UIAlertView(title: "Your turn", message: "Help is just a tap away. Try to keep up until the end (there is one)! Good luck.", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "Ok")
                self.yourTurn!.show()
            }
        }
        if alertView == yourTurn? {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: userHasBeenBriefedKey)
            beginQuiz()
        }
    }
}

