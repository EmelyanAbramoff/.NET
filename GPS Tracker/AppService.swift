//
//  AppService.swift
//  GPS Tracker
//
//  Created by Sergey Sergeyev on 08.04.16.
//  Copyright © 2016 gridlocate. All rights reserved.
//

import UIKit



enum ExceptionName : String {
    case ServerError = "ServerError"
}

enum DistanceFilterType : String {
  case ActiveMode = "ActiveMode", BackgroundMode = "BackgroundMode"
}

class AppService: NSObject {

    class func currentVersion() -> String {
        return NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
    }

    class func currentDeviceID() -> String {
        return NSUserDefaults.standardUserDefaults().objectForKey("GridLocateDeviceID") as! String
    }
    
    class func getLocationRegionSize() -> Double {
        return (NSBundle.mainBundle().infoDictionary!["LocationRegionSize"]?.doubleValue)!
    }
  
    class func getDistanceFilter(mode: DistanceFilterType) -> Double {
      if let dict = NSBundle.mainBundle().infoDictionary?["LocationDistanceFilter"] as? [String:AnyObject] {
        return dict[mode.rawValue]?.doubleValue ?? 0
      }
      return 0
    }
  
  
    class func getLocationUpdateTimeSec() -> Int {
        return (NSBundle.mainBundle().infoDictionary!["LocationUpdateTimeSec"]?.integerValue)!
    }    
    
    class func isLocationUpdateLoggingFile() -> Bool {
        return (NSBundle.mainBundle().infoDictionary!["LocationUpdateLoggingFile"]?.boolValue)!
    }
    
    class func isLocationUpdateLoggingNotification() -> Bool {
        return (NSBundle.mainBundle().infoDictionary!["LocationUpdateLoggingNotification"]?.boolValue)!
    }
}
