//
//  PleaseWaitViewController.swift
//  Sonji
//
//  Created by Daniel Schlaug on 7/13/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import UIKit

class PleaseWaitViewController: UIViewController {
    @IBOutlet var messageLabel: UILabel
    var waitUntilTime:NSDate? {
    didSet {
        updateTime()
    }
    }
    var timer:NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTime()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "updateTime", userInfo: nil, repeats: true)
        self.timer.tolerance = 5
    }
    
    func updateTime() {
        if let targetTime = waitUntilTime {
            if targetTime.compare(NSDate()) == NSComparisonResult.OrderedAscending {
                self.timer?.invalidate()
                self.timer = nil
                (parentViewController as? CardSetViewController)?.displayNext()
            } else {
                let interval = targetTime.timeIntervalSinceNow
                let hours:Int = Int(interval/60/60)
                let minutes:Int = Int((interval%(60*60))/60)
                let timeMessage = hours > 0 ? " \(hours + 1) hours" : " \(minutes + 1) min"
                let message = "Now ponder what you've learned for a bit and come back in" + timeMessage
                messageLabel.text = message
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
