//
//  RootViewController.swift
//  Sonji
//
//  Created by Daniel Schlaug on 6/29/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var cardSetViewController: CardSetViewController!
    var _centerX: CGFloat {
    return self.view.bounds.width/2
    }
    
    // Gesture recognizers
    var rightEdgePanGesture: UIScreenEdgePanGestureRecognizer!
    var leftEdgePanGesture: UIScreenEdgePanGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        // Configure the card view controller and add it as a child view controller.
        self.cardSetViewController = CardSetViewController()
        self.cardSetViewController.dataSource = modelController
        
        let startingViewController: UIViewController = self.storyboard.instantiateViewControllerWithIdentifier("SoundTestViewController") as UIViewController
        let dummy = startingViewController.view
        self.cardSetViewController.currentViewController = startingViewController

        self.addChildViewController(self.cardSetViewController)
        self.view.addSubview(self.cardSetViewController.view)

        var cardSetViewRect = self.view.bounds
        self.cardSetViewController.view.frame = cardSetViewRect

        self.cardSetViewController.didMoveToParentViewController(self)
        
        
        
        // Add Screen Edge Pan Gesture
        rightEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: "rightEdgePan:")
        leftEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: "leftEdgePan:")
        rightEdgePanGesture.edges = UIRectEdge.Right
        leftEdgePanGesture.edges = UIRectEdge.Left
        enableScreenEdgePan()
    }
    
    func leftEdgePan(sender: UIScreenEdgePanGestureRecognizer) {
        switch sender.state {
        case .Began:
            cardSetViewController.displayPrevious()
        default:
            break
        }
    }
    func rightEdgePan(sender:UIScreenEdgePanGestureRecognizer) {
        switch sender.state {
        case .Began:
            cardSetViewController.displayNext()
        default:
            break
        }
    }
    
    func soundTestPassed() {
        
    }
    
    func enableScreenEdgePan() {
        self.view.addGestureRecognizer(rightEdgePanGesture)
        self.view.addGestureRecognizer(leftEdgePanGesture)
    }
    
    func disableScreenEdgePan() {
        self.view.removeGestureRecognizer(rightEdgePanGesture)
        self.view.removeGestureRecognizer(leftEdgePanGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var modelController: ModelController {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        if !_modelController {
            _modelController = ModelController(storyboard: self.storyboard)
        }
        return _modelController!
    }

    var _modelController: ModelController? = nil

    
    //MARK Delegate methods
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
}

