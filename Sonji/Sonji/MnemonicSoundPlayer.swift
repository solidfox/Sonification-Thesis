//
//  MnemonicSoundPlayer.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/11/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import AVFoundation

class MnemonicSoundPlayer {
    
    var player: AVAudioPlayer?
    let _noLoopMarker = "|"
    var loop = false
    let _word:String
    
    var queue = NSOperationQueue()
    
    init(word:String) {
        _word = word
        queue.addOperationWithBlock {
            var soundURL = NSBundle.mainBundle().URLForResource("[\(word)]", withExtension: ".m4a", subdirectory: "/Sound Effects")
            if !soundURL {
                soundURL = NSBundle.mainBundle().URLForResource("[\(word)]\(self._noLoopMarker)", withExtension: ".m4a", subdirectory: "/Sound Effects")
                self.loop = false
            } else {
                self.loop = true
            }
            if soundURL {
                let player = AVAudioPlayer(contentsOfURL: soundURL, fileTypeHint: AVFileTypeAppleM4A, error: nil)
                player.prepareToPlay()
                player.volume = 0.3
                player.play()
                self.player = player
            } else {
                NSLog("Could not find [\(word)]\(self._noLoopMarker).m4a")
            }
        }
    }
    
    func stop() {
        queue.addOperationWithBlock {
            self.player?.stop()
            self.player = nil
        }
    }
}
