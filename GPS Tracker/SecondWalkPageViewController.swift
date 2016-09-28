//
//  SecondWalkPageViewController.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 25/12/15.
//  Copyright © 2015 gridlocate. All rights reserved.
//

import UIKit
import TTTAttributedLabel


class SecondWalkPageViewController: BWWalkthroughPageViewController, TTTAttributedLabelDelegate {

    @IBOutlet var lbl: TTTAttributedLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let str = "Family can create a FREE GridLocate account online, and add your device."
        lbl.text = str as String
        
        let range : NSRange = (str as NSString).rangeOfString("online")
        
        lbl.addLinkToURL(NSURL(string: "https://gridlocate.com/mobile?utm_source=gpstracker&;utm_medium=inapp&utm_campaign=welcomepage2")!, withRange: range)
        lbl.delegate = self
    }

    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
