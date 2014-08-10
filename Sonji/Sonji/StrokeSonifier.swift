//
//  StrokeSonifier.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/4/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import Foundation
import UIKit
//import DanielsKit
//import KanjiVGKit
//import BezierKit

let StrokeSonifierSpanScalingFactor = CGFloat(0.8)

class StrokeSonifier: PointSequenceReceptor {
    let _notePlayer: MusicalInstrument
    let referenceStroke: KVGStroke
    let instrumentForType: Dictionary<Character, MusicalInstrumentKind> = [
        "㇑": .Piano,
        "㇐": .Piano,
        "㇕": .Piano,
        "㇆": .Piano, // TODO Something else?
        "㇒": .Harp,
        "㇏": .Harp,
        "㇔": .Piano
    ]
    let _horizontalTypes: [Character] = ["㇐", "㇕", "㇏", "㇒", "㇆"]
    let _verticalTypes: [Character] = ["㇑", "㇕", "㇏", "㇒", "㇔", "㇆"]
    let _dotTypes: [Character] = ["㇔"]
    let _horizontalNotes = ["F5", "A#5", "C6", "F6"]
    let _verticalNotes = ["D6", "C6", "A#5", "D5"]
    let _dotNotes = ["G5", "A5", "A#5"]
    let audioQueue = dispatch_queue_create("com.schlaug.sonji.audioHandlingQueue", DISPATCH_QUEUE_SERIAL)
    
    var noteSpanOrigin: CGPoint!
    var currentOffset = CGPoint(x:0,y:0)
    var canvasBounds: CGSize {
    get {
        return CGSizeApplyAffineTransform ( referenceStroke.bounds, toCanvasTransform );
    }
    set {
        let sx = newValue.width / referenceStroke.bounds.width
        let sy = newValue.height / referenceStroke.bounds.height
        toCanvasTransform = CGAffineTransformMakeScale(sx,sy)
        fromCanvasTransform = CGAffineTransformMakeScale(1/sx,1/sy)
    }
    }
    
    var toCanvasTransform = CGAffineTransformMakeScale(1,1)
    var fromCanvasTransform = CGAffineTransformMakeScale(1,1)
    
    
    var __horizontalNotePositions: [CGFloat]!
    var _horizontalNotePositions: [CGFloat] {
        if !__horizontalNotePositions {
            var positions:[CGFloat] = []
            let type = referenceStroke.type
            if find(_horizontalTypes, type) {
                let strokeBounds = referenceStroke.path.bounds
                let span = strokeBounds.width * StrokeSonifierSpanScalingFactor
                let nNotes = Double(_verticalNotes.count)
                let noteDistance = span / CGFloat(nNotes)
                for i in indices(_verticalNotes) {
                    positions.append(CGFloat(i + 1) * noteDistance)
                }
            }
            __horizontalNotePositions = positions
        }
        return __horizontalNotePositions
    }
    var __verticalNotePositions: [CGFloat]!
    var _verticalNotePositions: [CGFloat] {
        if !__verticalNotePositions {
            var positions: [CGFloat] = []
            let type = referenceStroke.type
            if find(_verticalTypes, type) {
                var notes = _verticalNotes
                if find(_dotTypes, type) {
                    notes = _dotNotes
                }
                let strokeBounds = referenceStroke.path.bounds
                let span = strokeBounds.height * StrokeSonifierSpanScalingFactor
                let nNotes = Double(notes.count)
                let noteDistance = span / CGFloat(nNotes)
                for i in indices(notes) {
                    positions.append(CGFloat(i + 1) * noteDistance)
                }
            }
            __verticalNotePositions = positions
        }
        return __verticalNotePositions
    }
    
    
    init(referenceStroke: KVGStroke) {
        self.referenceStroke = referenceStroke

        let type = referenceStroke.type
        
        let instrument = instrumentForType[type]
        _notePlayer = MusicalInstrument.sharedInstance(instrument:instrument!)
        _notePlayer.prepareNotes(_horizontalNotes + _verticalNotes + _dotNotes)
    }
    
    func startSequenceAtPoint(point: CGPoint, inBounds bounds: CGSize?) {
        dispatch_async(audioQueue) {
            if bounds {
                self.canvasBounds = bounds!
            }
            let scaledPoint = CGPointApplyAffineTransform(point, self.fromCanvasTransform)
            let referenceStartingPointOffset = (self.referenceStroke.path.firstPoint - self.referenceStroke.path.bounds.origin)
            self.noteSpanOrigin = scaledPoint - referenceStartingPointOffset
            self.currentOffset = referenceStartingPointOffset
//        NSLog("\(noteSpanOrigin), offset: \(currentOffset)")
        }
    }
    
    func addPointToSequence(point: CGPoint) {
        dispatch_async(audioQueue) {
            let scaledPoint = CGPointApplyAffineTransform(point, self.fromCanvasTransform)
            let newOffset = scaledPoint - self.noteSpanOrigin
            for i in indices(self._verticalNotePositions) {
                let notePosition = self._verticalNotePositions[i]
                if min(newOffset.y, self.currentOffset.y) <= notePosition && notePosition < max(newOffset.y, self.currentOffset.y) {
                    self._notePlayer.playNote(self._verticalNotes[i])
                }
            }
            for i in indices(self._horizontalNotePositions) {
                let notePosition = self._horizontalNotePositions[i]
                if min(newOffset.x, self.currentOffset.x) <= notePosition && notePosition < max(newOffset.x, self.currentOffset.x) {
                    self._notePlayer.playNote(self._horizontalNotes[i])
                }
            }
            self.currentOffset = newOffset
        }
        
    }
    
    func endSequence() {
//        dispatch_async(audioQueue) {self._notePlayer.stop()}
    }
    
}
