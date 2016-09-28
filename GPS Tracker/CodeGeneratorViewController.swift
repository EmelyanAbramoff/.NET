//
//  CodeGeneratorViewController.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 06/12/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class CodeGeneratorViewController: UIViewController, TTTAttributedLabelDelegate {

    @IBOutlet var lbl: TTTAttributedLabel!
    
    @IBOutlet weak var deviceId: UILabel!
    
    @IBOutlet weak var oneTimeCode: UILabel!
    
    var locationService = LocationService()
    
    var codeExpired : Bool = true
    
    var myTimer: NSTimer? = nil

    var countdown = 0
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        trackScreen("connect-page")
        
        let str = "Family and friends can track your location online at https://gridlocate.com. They will need the following device id and one time password."
        lbl.delegate = self
        lbl.text = str as String
        
        let range : NSRange = (str as NSString).rangeOfString("https://gridlocate.com")
        
        lbl.addLinkToURL(NSURL(string: "https://gridlocate.com/mobile?utm_source=gpstracker&utm_medium=inapp&utm_campaign=unlockpage")!, withRange: range)

    }
    
    override func viewDidAppear(animated: Bool) {
        let share : UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_share_white"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(CodeGeneratorViewController.shareTapped(_:)))
        self.navigationItem.setRightBarButtonItems([share ], animated: true)
        self.navigationController?.navigationBar.tintColor = UIColor(white: 1.0, alpha: 1.0)
        
    }

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "One Time Code"
        // Do any additional setup after loading the view.
        getPassword()
        
    }
    
    func shareTapped(sender:UIButton) {
        trackEvent(Cateogary.CONNECT_PAGE.rawValue, action: Action.EVENT_CONNECT_PAGE_SHARE.rawValue, label: Label.COUNT.rawValue, value: nil)
        let url = NSURL(string: "https://gridlocate.com/register")
        let share = UIActivityViewController(activityItems: ["I've installed GridLocate GPS Tracker.  You can track my location at ", url!, "using the following details deviceId: \(deviceId.text!), password:  \(oneTimeCode.text!).  This code expires in 30 minutes." ], applicationActivities: nil)
        self.presentViewController(share, animated: true, completion: nil)
    }
    
    func getPassword(){
        
        SwiftSpinner.show("Fetching \nyour Onetime Code...")
        
        
        if Reachability.isConnectedToNetwork() == true {
            

        locationService.getCode{
            (device , code, expiry) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if expiry == 0.0 {
                    SwiftSpinner.hide()
                    let alertController = UIAlertController(title: "Something wrong happened.", message: "Make sure your device is connected to the internet.", preferredStyle: .Alert)
                    
                    let cancelAction = UIAlertAction(title: "Ok", style: .Default ) { (action) in
                        
                    }
                    alertController.addAction(cancelAction)
                    
                    
                    self.presentViewController(alertController, animated: true) {
                        // ...
                    }

                } else {
                    
                
                 let interval  = ((expiry - NSDate().timeIntervalSince1970 * 1000) / 60000 )
                 self.countdown = Int(interval)
                self.deviceId.text = device
                self.oneTimeCode.text = code
                self.myTimer = NSTimer.scheduledTimerWithTimeInterval( 60, target: self, selector:#selector(CodeGeneratorViewController.countDownTick), userInfo: nil, repeats: true)

                SwiftSpinner.hide()
                }
            })
            
        }
            
        } else {
            print("Internet connection FAILED")
            SwiftSpinner.hide()
            let alertController = UIAlertController(title: "No internet connection !", message: "Make sure your device is connected to the internet.", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default ) { (action) in
            }
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true) {
                // ...
            }
        }
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func countDownTick() {
        countdown -= 1
        
        if (countdown == 0) {
            myTimer!.invalidate()
            myTimer=nil
        }
        
        codeExpired = false
        
        
    }

    @IBAction func refreshPassword(sender: AnyObject) {
            trackEvent(Cateogary.CONNECT_PAGE.rawValue, action: Action.EVENT_CONNECT_PAGE_NEW_CODE.rawValue, label: Label.COUNT.rawValue, value: nil)
            self.getPassword()
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
