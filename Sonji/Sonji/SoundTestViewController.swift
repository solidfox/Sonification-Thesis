//
//  SoundTestViewController.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/11/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit
//import BezierKit
import AVFoundation

class SoundTestViewController: UIViewController, AVSpeechSynthesizerDelegate {
    @IBOutlet var drawHereLabel: UILabel
    @IBOutlet var canvas: CharacterCanvas
    var userPath = BezierPath()
    var templatePath = BezierPath(SVGdAttribute: "M254.07,80.823C212.478,14.009,65.572,11.475,69.558,88.788 c4.425,85.84,209.292,46.46,213.717,141.593c1.4,30.101-24.861,51.595-72.566,59.734C99.204,309.142,48.761,254.274,46.94,229.078")
    var siri:AVSpeechSynthesizer?
    var siriSpokeNTimes = 1
    var siriSays:AVSpeechUtterance!
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        siri = AVSpeechSynthesizer()
        siri!.delegate = self
    }

    override func viewDidLoad() {
        let panGesture = UIPanGestureRecognizer(target: self, action: "panRecognized:")
        canvas.addGestureRecognizer(panGesture)
        siriSays = AVSpeechUtterance(string: "For this experiment please keep your volume at a perceivable level. Feel free to use headphones for the best experience. To begin draw the letter. S. . I repeat, draw the letter. S.")
        siriSays.postUtteranceDelay = 0.5
        siriSays.voice = AVSpeechSynthesisVoice(language: "en-US")
        siriSays.rate = 0.27
        siri?.speakUtterance(siriSays)
    }
    
    override func viewDidDisappear(animated: Bool) {
        siri?.stopSpeakingAtBoundary(AVSpeechBoundary.Word)
        siri = nil
    }
    
    func panRecognized(sender: UIPanGestureRecognizer) {
        let point = sender.locationInView(canvas)
        switch sender.state {
        case .Began:
            UIView.animateWithDuration(0.5,
                delay: 0, options:nil, animations: {
                    self.drawHereLabel.alpha = 0
                }, completion: {_ in
                })
            userPath.add(.MoveToPoint(point))
            canvas.startSequenceAtPoint(point, inBounds: canvas.bounds.size)
        case .Changed:
            userPath.add(.LineToPoint(point))
            canvas.addPointToSequence(point)
        case .Ended:
            userPath.add(.LineToPoint(point))
            canvas.addPointToSequence(point)
            let score = userPath.compareTo(otherPath: templatePath, withInvariances: Invariant.All)
            if score > 0.7 {
                canvas.animateSuccess()
                let cardSet = self.parentViewController as CardSetViewController
                siri?.stopSpeakingAtBoundary(AVSpeechBoundary.Word)
                siri = nil
                cardSet.displayNext()
            } else {
                canvas.animateFailure()
                userPath = BezierPath()
                if siri {
                    if !siri!.speaking {
                        siri?.speakUtterance(siriSays)
                    }
                }
                drawHereLabel.text = "Try again"
                UIView.animateWithDuration(0.5,
                    delay: 0, options:nil, animations: {
                        self.drawHereLabel.alpha = 1
                    }, completion: {_ in
                    })
            }
        case .Cancelled, .Failed:
            canvas.animateFailure()
            userPath = BezierPath()
        case .Possible:
            break
        }
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didFinishSpeechUtterance utterance: AVSpeechUtterance!) {
        if synthesizer {
            if (siriSpokeNTimes < 2) {
                synthesizer.speakUtterance(utterance)
                ++siriSpokeNTimes
            }
        }
    }
}
