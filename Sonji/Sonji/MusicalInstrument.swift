//
//  MusicalInstrument.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/4/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import AVFoundation

enum MusicalInstrumentKind: String {
    case Piano = "Piano"
    case Harp = "Harp"
}

class MusicalInstrument {
    class func sharedInstance(#instrument: MusicalInstrumentKind) -> MusicalInstrument {
        struct SingletonPiano {
            static let instance = MusicalInstrument(kind:.Piano)
        }
        struct SingletonHarp {
            static let instance = MusicalInstrument(kind:.Harp)
        }
        
        switch instrument {
        case .Piano:
            return SingletonPiano.instance
        case .Harp:
            return SingletonHarp.instance
        }
    }
    
    let kind: MusicalInstrumentKind
    var _audioDataForNote: Dictionary<String, NSData> = [:]
    var _audioPlayersForNote: Dictionary<String, [AVAudioPlayer]> = [:]
    var _playerIndexForNote: Dictionary<String, Int> = [:]
    
    init(kind: MusicalInstrumentKind) {
        self.kind = kind
    }
    
    func playNote(note: String) {
        var players: [AVAudioPlayer]! = _audioPlayersForNote[note]
        if !players {
            prepareNotes([note])
            players = _audioPlayersForNote[note]
        }
        let index = _playerIndexForNote[note]
        let player = players[index!]
        if player.playing {
            player.currentTime = 0
        } else {
            player.play()
        }
        _playerIndexForNote[note] = (index! + 1) % players.count
    }
    
    func prepareNotes(notes: [String]) {
        for note in notes {
            if !_audioDataForNote[note] {
                let noteURL = NSBundle.mainBundle().URLForResource(note, withExtension: ".m4a", subdirectory: "/Instruments/\(self.kind.toRaw())")
                if !noteURL || !NSFileManager.defaultManager().fileExistsAtPath(noteURL.path) {
                    NSLog("File for note \(note) didn't exist at /Instruments/\(self.kind.toRaw())/\(note).m4a")
                    fatalError("Note file not found.")
                }
                var noteData = NSData(contentsOfURL: noteURL)
                assert(noteData != nil, "noteData was nil")
                var players: [AVAudioPlayer] = []
                for _ in 1...3 {
                    var error: NSError?
                    let player = AVAudioPlayer(data: noteData, fileTypeHint: AVFileTypeAppleM4A, error: &error)
                    assert(!error, "Error loading audio data.")
                    player.prepareToPlay()
                    player.volume = 0.7
                    players += player
                }
                _audioPlayersForNote[note] = players
                _audioDataForNote[note] = noteData
                _playerIndexForNote[note] = 0
            }
        }
    }
    
    func stop() {
        for (_, players) in _audioPlayersForNote {
            for player in players {
                player.pause()
                player.currentTime = 0                
            }
        }
    }
}
