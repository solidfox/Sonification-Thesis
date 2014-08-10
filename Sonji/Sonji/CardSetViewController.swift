//
//  CardSetViewController.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/6/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

@objc @class_protocol protocol CardSetViewControllerDataSource {
    @optional func next() -> UIViewController?
    func cardSetViewController(cardSetViewController: CardSetViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    func cardSetViewController(cardSetViewController: CardSetViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
}

enum CardTransitionDirection {
    case Forward
    case Backward
}

class CardSetViewController: UIViewController {
    
    weak var dataSource: CardSetViewControllerDataSource?
    
    var _currentViewController:UIViewController?
    
    var currentViewController:UIViewController? {
    get {
        return _currentViewController
    }
    set {
        if let newC = newValue {
            if let oldC = _currentViewController {
                newC.view.frame = oldC.view.frame
                oldC.willMoveToParentViewController(nil)
            } else {
                newC.view.frame = _defaultContentFrame
            }
            self.addChildViewController(newC)
            self.view.addSubview(newC.view)
            if let oldC = _currentViewController {
                oldC.view.removeFromSuperview()
                oldC.removeFromParentViewController()
            }
            newC.didMoveToParentViewController(self)
        }
        _currentViewController = newValue
    }
    }
    
    func displayNext() -> Bool {
        var success = false
        if dataSource {
            if let currentC = currentViewController {
                if let nextC = dataSource!.cardSetViewController(self, viewControllerAfterViewController: currentC) {
                    _cycleFromViewController(currentC, toViewController: nextC, inDirection: .Forward)
                    success = true
                }
            }
        }
        return success
    }
    
    func displayPrevious() -> Bool {
        var success = false
        if dataSource {
            if let currentC = currentViewController {
                if let previousC = dataSource!.cardSetViewController(self,
                    viewControllerBeforeViewController: currentC) {
                        _cycleFromViewController(currentC, toViewController: previousC, inDirection: .Backward)
                        success = true
                }
            }
        }
        return success
    }

    var _defaultContentFrame: CGRect {return self.view.bounds}
    var _nextViewFrame: CGRect {
        let screen = UIScreen.mainScreen()
        let width = screen.bounds.width // WARNING this will not work for non-fullscreen parent view controllers
        let origin = CGPoint(x: width*1.5, y: 0)
        let size = self.view.bounds.size
        let rect = CGRect(origin: origin, size: size)
        return rect
    }
    var _previousViewFrame: CGRect {return _defaultContentFrame}
    
    
    func _cycleFromViewController(oldC:UIViewController,
        toViewController newC:UIViewController,
        inDirection direction: CardTransitionDirection) {
            
            _currentViewController = newC
            
            oldC.willMoveToParentViewController(nil)
            self.addChildViewController(newC)
            
            // Animate!
            var newCStartFrame: CGRect!
            var oldCEndFrame: CGRect!
            var newCEndFrame: CGRect!
            switch direction {
            case .Forward:
                oldCEndFrame = oldC.view.frame
                newCStartFrame = self._nextViewFrame
                newCEndFrame = oldC.view.frame
            case .Backward:
                oldCEndFrame = self._nextViewFrame
                newCStartFrame = oldC.view.frame
                newCEndFrame = oldC.view.frame
            }
            
            self.addChildViewController(newC)
            switch direction {
            case .Forward:
                self.view.insertSubview(newC.view, aboveSubview: oldC.view)
            case .Backward:
                self.view.insertSubview(newC.view, belowSubview: oldC.view)
            }
            
            
            newC.view.frame = newCStartFrame
            
            UIView.animateWithDuration(0.25, delay: NSTimeInterval(0),
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: {
                    oldC.view.frame = oldCEndFrame
                    newC.view.frame = newCEndFrame
                }, completion: { completed in
                    oldC.view.removeFromSuperview()
                    oldC.removeFromParentViewController()
                    newC.didMoveToParentViewController(self)
                }
            )
    }
    
}
