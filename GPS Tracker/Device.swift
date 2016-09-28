//
//  Device.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 29/11/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import Foundation
import UIKit

struct Device {
    
    var deviceData : [String : AnyObject]
    
    
    init(registeredName : String){
        
        let device = UIDevice()
        deviceData = [String : AnyObject]()
        
        
        //        device_tz: deviceSchema.device_tz,
        //device_frequency: deviceSchema.device_frequency,
        
        self.deviceData["pincode"] = randomStringWithLength(4)
        self.deviceData["device_soft_id"] = UIDevice.currentDevice().identifierForVendor!.UUIDString
        self.deviceData["device_name"] = registeredName
        self.deviceData["device_versionname"] = NSBundle.mainBundle().releaseVersionNumber
        self.deviceData["device_versioncode"] = NSBundle.mainBundle().buildVersionNumber
        self.deviceData["device_manufacturer"] = "Apple".lowercaseString
        self.deviceData["device_model"] = UIDevice.currentDevice().modelName
        self.deviceData["device_product"] = device.localizedModel
        self.deviceData["device_phoneno"] = "null"
        self.deviceData["device_imei"] = "null"
        self.deviceData["device_policeshare"] = 1
        self.deviceData["device_tz"] = ltzName();
        self.deviceData["product"] = "gpstracker"
        
    }
    
    func ltzName() -> String { return NSTimeZone.localTimeZone().name }
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
}