//
//  AppDelegate.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 16/11/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import UIKit
import Bugsnag

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sharedModel: LocationManagerBackground!
    let defaults = NSUserDefaults.standardUserDefaults()

    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        // UIApplicationLaunchOptionsLocationKey
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        if AppService.isLocationUpdateLoggingNotification() {
        let notify = UILocalNotification()
        notify.fireDate  = NSDate()
        notify.alertBody = launchOptions?[UIApplicationLaunchOptionsLocationKey] == nil ? "By User" : "By Location"
        notify.soundName = UILocalNotificationDefaultSoundName
                    application.scheduleLocalNotification(notify)
        }

        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        startBackgroundLocationManager()
        
        Bugsnag.startBugsnagWithApiKey("d9420b0a5d27f3a4cdd0af76cefcf495")

        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.None // remove before app release
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        startBackgroundLocationManager()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        startBackgroundLocationManager()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        startBackgroundLocationManager()
    }
    
    func startBackgroundLocationManager() {
        if self.defaults.stringForKey("GridLocateApiToken") != nil  {
            self.sharedModel = LocationManagerBackground.sharedManager
            self.sharedModel.startMonitoringLocation()
        }
    }

}

