//
//  LocationManagerBackground.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 02/01/16.
//  Copyright © 2016 gridlocate. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import Bugsnag


class LocationManagerBackground: NSObject, CLLocationManagerDelegate {
  
  private let regionName = "currentRegion"
  private let activationModeRegion = "region"
  private let updateInterval = AppService.getLocationUpdateTimeSec()
  private var locationSendTask = UIBackgroundTaskInvalid
  private var updateTimer: NSTimer?
  
  private var filteredLocationManager: CLLocationManager!
  
  private var databasePath : String
  private var locationService = LocationService()
  private var taskToken : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
  private var defaultRadius = CLLocationDistance(AppService.getLocationRegionSize())
  private var currentLocation : CLLocation? = nil
  private var requestCount = 0
  private var lastUpdateDate:NSDate? = nil
  
  class var IS_IOS_OR_LATER: Bool {
    let Device = UIDevice.currentDevice()
    let iosVersion = NSString(string: Device.systemVersion).doubleValue
    return iosVersion >= 8
  }
  
  class var sharedManager : LocationManagerBackground {
    struct Static {
      static let instance : LocationManagerBackground = LocationManagerBackground()
    }
    return Static.instance
  }
  
  private override init(){
    let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let docsDir = dirPaths.first
    
    self.databasePath = NSURL(fileURLWithPath: docsDir!).URLByAppendingPathComponent("location.db").URLString
    super.init()
  }
  
  func startMonitoringLocation() {
    print("start location update")

    if (filteredLocationManager != nil) {
      filteredLocationManager.stopUpdatingLocation()
    }

    
    self.filteredLocationManager = CLLocationManager()
    filteredLocationManager.delegate = self
    filteredLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    filteredLocationManager.activityType = CLActivityType.Fitness
    
    //This filter is really needed if you want to economy your battery life
    let defaultDistance = AppService.getDistanceFilter(DistanceFilterType.BackgroundMode)
    if defaultDistance > 0 {
      filteredLocationManager.distanceFilter = CLLocationDistance(defaultDistance)
    }
    
    filteredLocationManager.allowsBackgroundLocationUpdates = true
    filteredLocationManager.pausesLocationUpdatesAutomatically = false;
    
    if (LocationManagerBackground.IS_IOS_OR_LATER) {
      filteredLocationManager.requestAlwaysAuthorization()
    }
    
    filteredLocationManager.startUpdatingLocation();
    
    updateTimer = NSTimer.scheduledTimerWithTimeInterval((NSTimeInterval)(updateInterval), target: self,
                                                         selector: #selector(sendLastLocation), userInfo: nil, repeats: true)
    
    locationSendTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
      UIApplication.sharedApplication().endBackgroundTask(self.locationSendTask)
      self.locationSendTask = UIBackgroundTaskInvalid
    })
    assert(locationSendTask != UIBackgroundTaskInvalid)
  }
  
  func restartMonitoringLocation() {
    print("restart location update")
    filteredLocationManager.stopUpdatingLocation()
    if (LocationManagerBackground.IS_IOS_OR_LATER) {
      filteredLocationManager.requestAlwaysAuthorization()
    }
    filteredLocationManager.startUpdatingLocation()
  }
  
  func sendLastLocation(){
    if let location = filteredLocationManager.location {
      self.processNewLocation(filteredLocationManager, location: location, withTime: NSDate(timeIntervalSinceNow: 1))
    }
  }
  
  func stopMonitoringLocation(){
    print("stop location update")
    if (filteredLocationManager != nil) {
      filteredLocationManager.stopUpdatingLocation()
    }
  }
  
  func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
    print("problem in deferred update",error?.localizedDescription)
  }
  
  func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
    let needRegionUpdate = currentLocation == nil
    currentLocation = newLocation
    if needRegionUpdate {
      updateRegion(manager)
    }
    processNewLocation(manager, location: currentLocation!, withTime: currentLocation!.timestamp)
  }
  
  private func updateRegion(manager: CLLocationManager) {
    // stop monitoring for all regions
    if currentLocation == nil {
      return
    }
    for region in manager.monitoredRegions {
      manager.stopMonitoringForRegion(region)
    }
    // add monitoring region
    let rg = CLCircularRegion(center: currentLocation!.coordinate, radius: defaultRadius, identifier: regionName)
    manager.startMonitoringForRegion(rg)
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let needRegionUpdate = currentLocation == nil
    currentLocation = locations.last
    if needRegionUpdate {
      updateRegion(manager)
    }
    let coordLatLon = currentLocation!.coordinate
    let latitude: Double  = coordLatLon.latitude
    let longitude: Double = coordLatLon.longitude
    print("Location Updated at  \(currentLocation!.timestamp)==\(latitude), \(longitude)")
    
    processNewLocation(manager, location: currentLocation!, withTime: currentLocation!.timestamp)
  }
  
  func processNewLocation(manager: CLLocationManager, location : CLLocation, withTime: NSDate) {
    
    // to increase the runtime of the background task
    if taskToken == UIBackgroundTaskInvalid {
      logEvent("begin task", location: nil)
      
      taskToken = UIApplication.sharedApplication().beginBackgroundTaskWithName("UpdateLocation", expirationHandler: { () -> Void in
        self.logEvent("interrupted task", location: nil)
        
        UIApplication.sharedApplication().endBackgroundTask(self.taskToken)
        self.taskToken = UIBackgroundTaskInvalid
      })
    }
    
    updateLocation(manager, location: location, withTime: withTime) {
      self.logEvent("success task", location: nil)
      
      UIApplication.sharedApplication().endBackgroundTask(self.taskToken)
      self.taskToken = UIBackgroundTaskInvalid
    }
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print(error.description)
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    manager.stopMonitoringForRegion(region)
    if currentLocation == nil {
      currentLocation = manager.location
    }
    if currentLocation != nil {
      let rg = CLCircularRegion(center: (currentLocation?.coordinate)!, radius: defaultRadius, identifier: regionName)
      manager.startMonitoringForRegion(rg)
      //Region exit MUST send data to server
      lastUpdateDate = nil
      updateLocation(manager, location: currentLocation!, withTime: currentLocation!.timestamp, completionHandler: { })
    }
  }
  
  func updateLocation(manager: CLLocationManager!, location: CLLocation!, withTime: NSDate, completionHandler: ()->Void){
    
    if lastUpdateDate != nil && Int(withTime.timeIntervalSinceDate(lastUpdateDate!)) < updateInterval {
      return
    }
    lastUpdateDate = withTime
    
    let locationDB = FMDatabase(path: databasePath as String)
    let locationToStore = CurrentLocation(location: location)
    
    if Reachability.isConnectedToNetwork() == true {
      if locationDB.open() {
        //                    let sql2 = "DELETE FROM LOCATIONS"
        //                    let ret = locationDB.executeUpdate(sql2, withArgumentsInArray: nil)
        
        let querySQL = "SELECT * FROM LOCATIONS"
        let results:FMResultSet? = locationDB.executeQuery(querySQL, withArgumentsInArray: nil)
        while results?.next() == true {
          //First reverse geocode then update to server
          let lat = results!.doubleForColumn("LATITUDE")
          let long = results!.doubleForColumn("LONGITUDE")
          let accuracy = results!.stringForColumn("ACCURACY_LEVEL")
          let battery = Int(results!.doubleForColumn("BATTERY_STATUS"))
          
          let updateTime = results!.doubleForColumn("UPDATED_TIME")
          let lastLoc = CLLocation(latitude: lat, longitude: long)
          
          logEvent("pre old", location: lastLoc)
          self.requestCount = self.requestCount + 1
          
          reverseGeoCodeAndSend(lastLoc, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: LocationUpdateMode.Missed)  {(isError ) -> Void  in
            self.requestCount = self.requestCount - 1
            
            if isError {
              print("Error Occurred while updating !")
              self.logBugsnagServerError(.Missed)
              self.logEvent("post old err", location: lastLoc)
            }
            else {
              if locationDB.open(){
                let SQL = "DELETE FROM LOCATIONS WHERE UPDATED_TIME = ?"
                _ = locationDB.executeUpdate (SQL, withArgumentsInArray: [updateTime])
                print("Deleted")
              }
              else {
                print("Unable to open the DB")
                Bugsnag.notify(NSException(name: "FailureInOpeningDatabase", reason: "Error: \(locationDB.lastErrorMessage())", userInfo: nil ))
              }
              self.logEvent("post old ok", location: lastLoc)
            }
            if self.requestCount == 0 { completionHandler() }
          }
        }
        
      } else {
        Bugsnag.notify(NSException(name: "FailureInOpeningDatabase", reason: "Error: \(locationDB.lastErrorMessage())", userInfo: nil ))
      }
      
      let updateTime = NSDate().timeIntervalSince1970 * 1000
      
      
        let accuracy = location.horizontalAccuracy.description
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setValue(accuracy, forKey: defaultsKeys.accuracy)
        
        
        
      let device = UIDevice.currentDevice()
      device.batteryMonitoringEnabled = true
      let battery = Int(device.batteryLevel * 100)
      
      logEvent("pre", location: location)
      self.requestCount = self.requestCount + 1
      
      reverseGeoCodeAndSend(location, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: LocationUpdateMode.Region) {(isError ) -> Void  in
        self.requestCount = self.requestCount - 1
        
        //Check if update was successful.
        if isError {
          self.addToDB(locationDB, locationToStore: CurrentLocation(location: location))
          self.logBugsnagServerError(.Region)
          self.logEvent("post err", location: location)
        } else {
          self.logEvent("post ok", location: location)
        }
        if self.requestCount == 0 { completionHandler() }
      }
      
      locationDB.close()
      
    } else {
      addToDB(locationDB, locationToStore: locationToStore)
      logEvent("add to db", location: location)
      completionHandler()
    }
  }
  
  
  func logEvent(prefix : String, location: CLLocation?) {
    let notify = UILocalNotification()
    var body : String = "empty"
    
    if let location = location {
      let lat = location.coordinate.latitude
      let lon = location.coordinate.longitude
      body = "\(prefix) \n lat: \(lat) \n lon: \(lon)"
    } else {
      body = "\(prefix)"
    }
    
    if AppService.isLocationUpdateLoggingNotification() {
      // Show notification
      let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
      UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
      notify.alertBody = body
      notify.fireDate  = NSDate()
      UIApplication.sharedApplication().scheduleLocalNotification(notify)
    }
    
    func reverseGeoCodeAndSend(location : CLLocation, updateTime : Double , accuracy : String, battery : Int, mode : LocationUpdateMode, completionHandler : (Bool, NSError?)->Void ){
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error)-> Void in
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                self.locationService.sendLocationUpdate(location , placemark: pm, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: mode) {
                    (isError, serverError) -> Void in
                    if isError == true {
                        SwiftSpinner.hide()
                        completionHandler(true, serverError) //true because there is error
                    }
                    else{
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        
//                        })
                        SwiftSpinner.hide()
                        completionHandler(false, serverError)    //False because there is no error
                    }
                }
            } else {
                
                SwiftSpinner.hide()
                completionHandler(true, error)
                print("Problem with the data received from geocoder")
            }
        })
    }
  }
  
  
  
  func addToDB(locationDB : FMDatabase , locationToStore : CurrentLocation){
    
    func logBugsnagServerError(mode: LocationUpdateMode, error: NSError?)
    {
        
        var info = ["version": AppService.currentVersion(),
                    "device_id": AppService.currentDeviceID(),
                    "mode": mode.rawValue] as [NSObject : AnyObject]
        
        if error != nil {
            info["error"] = error?.userInfo.description
        }
        Bugsnag.notify(NSException(name: ExceptionName.ServerError.rawValue, reason: "", userInfo: nil), withData: info)
    }
    
    locationDB.close()
  }
  
  
  
  func reverseGeoCodeAndSend(location : CLLocation, updateTime : Double , accuracy : String, battery : Int, mode : LocationUpdateMode, completionHandler : (Bool)->Void ){
    
    CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error)-> Void in
      if (error != nil) {
        print("Reverse geocoder failed with error" + error!.localizedDescription)
        return
      }
      
      if placemarks!.count > 0 {
        let pm = placemarks![0]
        self.locationService.sendLocationUpdate(location , placemark: pm, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: mode) {
          (isError, error) -> Void in
          if isError == true {
            SwiftSpinner.hide()
            completionHandler(true) //true because there is error
          }
          else{
            //                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //
            //                        })
            SwiftSpinner.hide()
            completionHandler(false)    //False because there is no error
          }
        }
      } else {
        
        SwiftSpinner.hide()
        completionHandler(true)
        print("Problem with the data received from geocoder")
      }
    })
  }
  
  
  func logBugsnagServerError(mode: LocationUpdateMode)
  {
    let info = ["version": AppService.currentVersion(),
                "device_id": AppService.currentDeviceID(),
                "mode": mode.rawValue] as [NSObject : AnyObject]
    
    Bugsnag.notify(NSException(name: ExceptionName.ServerError.rawValue, reason: "", userInfo: nil), withData: info)
  }
  
}

