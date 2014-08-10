//
//  MusicalNotePlayer.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/4/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import AVFoundation

class MusicalNotePlayer {
    class var sharedInstance: MusicalNotePlayer {
    struct Singleton {
        static let instance = MusicalNotePlayer()
        }
        return Singleton.instance
    }
    
    let _harp = MusicalInstrument.sharedInstance(instrument: .Harp)
    let _piano = MusicalInstrument.sharedInstance(instrument: .Piano)
    
    var standbyAudioPlayersForNote: Dictionary<String, [AVAudioPlayer]> = [:]
    
    func playNote(note:String, instrument:String) {
        switch instrument {
        case "Harp":
            _harp.playNote(note)
        case "Piano":
            _piano.playNote(note)
        default:
            break
        }
    }
    
    func prepareToPlayNotes(notes:[String]) {
        _harp.prepareNotes(notes)
        _piano.prepareNotes(notes)
    }
    
    func stop() {
        _harp.stop()
        _piano.stop()
    }
}
