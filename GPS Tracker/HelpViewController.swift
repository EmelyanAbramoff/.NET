//
//  HelpViewController.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 14/12/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class HelpViewController: UIViewController, TTTAttributedLabelDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    let defaults = NSUserDefaults.standardUserDefaults()

    
    @IBOutlet var lbl: TTTAttributedLabel!
    @IBOutlet weak var deviceid: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    
    
    
    @IBOutlet weak var tracking: UILabel!
    
    @IBOutlet weak var battery: UILabel!
    @IBOutlet weak var internet: UILabel!
    @IBOutlet weak var accuracy: UILabel!
    
    
    @IBOutlet weak var versionNumber: UILabel!
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Help"
        trackScreen("help-page")
        scrollView.contentSize.height = 1000

        deviceid.text = self.defaults.stringForKey("GridLocateDeviceID")
        deviceName.text = self.defaults.stringForKey("GridLocateDeviceName")
        
        let accuracyDigit:Float = self.defaults.floatForKey(defaultsKeys.accuracy) ?? 0
       
        accuracy.text =  " Accurate upto \(accuracyDigit) meters"
        
        versionNumber.text = NSBundle.mainBundle().releaseVersionNumber;
        tracking.text = getAccuracyString(accuracyDigit)
        
        if Reachability.isConnectedToNetwork() {
            internet.text = "Connected to Internet"
        } else {
            internet.text = "Internet not available"
        }
        
        let device = UIDevice.currentDevice()
        device.batteryMonitoringEnabled = true
        battery.text = "\(Int(device.batteryLevel * 100))%"
        
        
        let str = String("GridLocate helps others locate you in case of emergency or concern.\n\nThis app uses GPS/Wi-Fi to determine your accurate location and sends this information to our secure servers every time you change location.\n\nTrusted individuals who know your unique device-id and one time code can view your location and history at https://gridlocate.com. GridLocate can be deactivated by uninstalling the application. \n\nOur privacy policy is at https://gridlocate.com/privacy. \nFor help/feedback, visit us at https://gridlocate.freshdesk.com .")
        
    
        lbl.delegate = self
        lbl.text = str as String
        
        let range : NSRange = (str as NSString).rangeOfString("https://gridlocate.com/privacy")
        
        let range2 : NSRange = (str as NSString).rangeOfString("https://gridlocate.freshdesk.com")
        let range3 : NSRange = (str as NSString).rangeOfString("https://gridlocate.com")
        
        lbl.addLinkToURL(NSURL(string: "https://gridlocate.com/privacy?utm_source=gpstracker&utm_medium=inapp&utm_campaign=helppage")!, withRange: range)
        lbl.addLinkToURL(NSURL(string: "https://gridlocate.freshdesk.com/support/tickets/new?utm_source=gpstracker&utm_medium=inapp&utm_campaign=helppage")!, withRange: range2)
        lbl.addLinkToURL(NSURL(string: "https://gridlocate.com/mobile?utm_source=gpstracker&utm_medium=inapp&utm_campaign=helppage")!, withRange: range3)
    
    }
    
    func getAccuracyString(accuracy : Float) -> String {
        if accuracy <= 100.0 {
            return "Tracking is Good."
        }
        else {
            return "Tracking is Bad."
        }
    }

}
