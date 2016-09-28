//
//  ViewController.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 16/11/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Foundation
import Bugsnag

class ViewController: UIViewController, MKMapViewDelegate , CLLocationManagerDelegate, UITextFieldDelegate {

    private var locationUpdateMode = LocationUpdateMode.Alarm // Default for first update
    private let regionName = "currentRegion"
    var defaultDistance = CLLocationDistance(AppService.getLocationRegionSize())
    var currentLocation : CLLocation?

    let defaults = NSUserDefaults.standardUserDefaults()
    var color = UIColor(red: 26, green: 145, blue: 114, alpha: 0.9);
    var firstUpdate = false
    var regionUpdate = true
    var locationService = LocationService()
    var currentLocationString = ""
    lazy var lastUpdate : NSDate = NSDate()
    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var btnTimeUpdated: UIButton!
    @IBOutlet weak var btnLocationUpdated: UIButton!
    let locationManager = CLLocationManager()
    var authStatus = true
    var databasePath = NSString()
    var nameOfLocation = ""
    var lastLocation:CLLocation!;

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Do any additional setup after loading the view, typically from a nib.
        
        let filemgr = NSFileManager.defaultManager()
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        let docsDir = dirPaths.first
        
        self.databasePath = NSURL(fileURLWithPath: docsDir!).URLByAppendingPathComponent("location.db").URLString

        
        
        if !filemgr.fileExistsAtPath(databasePath as String) {
            
            let locationDB = FMDatabase(path: databasePath as String)
            
            if locationDB == nil {
                print("Error: \(locationDB.lastErrorMessage())")
            }
            
            if locationDB.open() {
                let sql_stmt = "CREATE TABLE IF NOT EXISTS LOCATIONS (ID INTEGER PRIMARY KEY AUTOINCREMENT, FIELD_ACTIVITY TEXT, VERSION_NAME TEXT, LONGITUDE DOUBLE, LATITUDE DOUBLE, ACCURACY_LEVEL TEXT, BATTERY_STATUS DOUBLE, UPDATED_TIME DOUBLE, TIMEZOME TEXT, FULL_ADDRESS TEXT, REVERSE_GEO_STATUS TEXT, MODE TEXT,COUNTRY_CODE INT,HASH_LOCATION TEXT, HASH_PRECISION INTEGER DEFAULT -1 )"
                
            
                if !locationDB.executeStatements(sql_stmt) {
                    print("Error: \(locationDB.lastErrorMessage())")
                    Bugsnag.notify(NSException(name: "Failure In Creating Table", reason: "Error: \(locationDB.lastErrorMessage())", userInfo: nil ))
                }
                locationDB.close()
            } else {
                print("Error: \(locationDB.lastErrorMessage())")
                Bugsnag.notify(NSException(name: "FailureInOpeningDatabase", reason: "Error: \(locationDB.lastErrorMessage())", userInfo: nil ))
            }
        }
    
    }
    
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Bugsnag.notify(NSException(name: "MemoryWarningByOS", reason: "Received Memory Warning From iOS", userInfo: nil))
        

    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
        trackScreen("map-page")
        //PLace the logic to show the walk through here
        //If it has obtained the token for the request then 
        
        
        if let _ = self.defaults.stringForKey("GridLocateApiToken") {
            //This means he is already logged in so no need to go through registration process

            
            if firstUpdate == false {
                SwiftSpinner.show("Updating...\n your location", animated: true)
            }
          self.locationManager.requestAlwaysAuthorization()
          self.locationManager.delegate = self
          self.locationManager.pausesLocationUpdatesAutomatically = false
          self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
          self.locationManager.activityType = CLActivityType.Fitness
          
          let defaultDistance = AppService.getDistanceFilter(DistanceFilterType.ActiveMode)
          if defaultDistance > 0 {
            locationManager.distanceFilter = CLLocationDistance(defaultDistance)
          }
          
          self.locationManager.startMonitoringSignificantLocationChanges()
          self.locationManager.startUpdatingLocation()
          
          self.Map.showsUserLocation = true
          
          currentLocation = self.locationManager.location
        }
        else{
            startRegisterProcess()
        }
                
    
        let share : UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_share_white"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ViewController.shareTapped(_:)))
        let unlock : UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_lock_open_white"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ViewController.unlockTapped(_:)))
        let help : UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_help_white"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ViewController.menuTapped(_:)))
        
        self.navigationItem.setRightBarButtonItems([help, unlock ,share ], animated: true)
        self.navigationController?.navigationBar.tintColor = UIColor(white: 1.0, alpha: 1.0)
        
    }
  
  func restartLocationUpdate(forImmediate: Bool) {
    self.locationManager.requestAlwaysAuthorization()
    self.locationManager.stopUpdatingLocation()
    self.locationManager.delegate = self
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    if (forImmediate) {
      self.locationManager.distanceFilter = kCLDistanceFilterNone
    } else {
      let defaultDistance = AppService.getDistanceFilter(DistanceFilterType.ActiveMode)
      if defaultDistance > 0 {
        locationManager.distanceFilter = CLLocationDistance(defaultDistance)
      } else {
        self.locationManager.distanceFilter = kCLDistanceFilterNone
      }
    }
    self.locationManager.startUpdatingLocation()

  }
  
  
    func startRegisterProcess(){
      
        showActionSheetAndRegister {
            (res) -> Void in
            
            if res == true {
                
                var message : String
                self.trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_REGISTRATION_FAILED.rawValue, label: Label.STATUS.rawValue, value: nil)
                
                
                if Reachability.isConnectedToNetwork() == true {
                    message = "Registration failed! \nPlease try again."
                }else{
                    message = "Please check your internet connection."
                }
                
                let alertController = UIAlertController(title: "Error Occurred", message: message, preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "OK", style: .Default ) { (action) in
                    self.startRegisterProcess()
                }
                alertController.addAction(cancelAction)
                
                
                self.presentViewController(alertController, animated: true) {
                    // ...
                }
                
                self.startRegisterProcess()

                
            } else {
                
              self.restartLocationUpdate(true);
                self.Map.showsUserLocation = true
                self.trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_REGISTRATION_SUCCESS.rawValue, label: Label.STATUS.rawValue, value: nil)
                SwiftSpinner.show("Device Registered \nLoading Map...")
            }
        }

    }
    

    
    

    func showActionSheetAndRegister( completionhandler : (Bool) -> Void)
    {
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Register", message: "Give this device a name\n (Minimum 4 chars or maximum 20 chars)", preferredStyle: .Alert)
        
        let nextAction: UIAlertAction = UIAlertAction(title: "Register", style: .Default) { action -> Void in
            
            let text = (actionSheetController.textFields?.first)!.text
            self.defaults.setObject(text, forKey: "GridLocateDeviceName")
            SwiftSpinner.show("Registering \nyour Device ...")
            
            self.locationService.sendRegistration(text!) {
                (response ) -> Void in
                if response == true {
                    SwiftSpinner.hide()
                    completionhandler(true)
                } else {
                    SwiftSpinner.hide()
                    completionhandler(false)
                }
            }
            
        }
        
        actionSheetController.addAction(nextAction)
        
        //Add a text field
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            //TextField configuration
            textField.textColor = UIColor.blueColor()
            textField.placeholder = "Device Name e.g. Sam's Phone"
            textField.addTarget(self, action: #selector(ViewController.textChanged(_:)), forControlEvents: .EditingChanged)
            textField.delegate = self
            
        }
        nextAction.enabled  = false
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    
    //Function to enable the text field if the text has benn enterred in the text box.
    //This will not allow the user to enter the empty texts
    //And it will dismiss if the user has enterred a genuine text field value
    
    func textChanged(sender:AnyObject) {
        let tf = sender as! UITextField
        var resp : UIResponder! = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder() }
        let alert = resp as! UIAlertController
        let nextAction: UIAlertAction = alert.actions[0]
        let str=tf.text;
        nextAction.enabled = (str!.characters.count>=4)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool
    {
        let maxLength = 20
        let currentString: NSString = textField.text!
        let newString: NSString =
        currentString.stringByReplacingCharactersInRange(range, withString: string)
        return newString.length <= maxLength
    }
  
    
    func shareTapped(sender:UIButton) {
        
        let url = NSURL(string: "https://gridlocate.com/map/\(Geohash.encode(latitude:lastLocation.coordinate.latitude , longitude:lastLocation.coordinate.longitude,8))")

        let share = UIActivityViewController(activityItems: ["Hey! I am at \(currentLocationString). View my location:", url!   ], applicationActivities: nil)
        self.presentViewController(share, animated: true, completion: nil)
        trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_MAP_PAGE_SHARE.rawValue, label: Label.INVITE_COUNT.rawValue, value: nil)
    }

    
    func unlockTapped (sender:UIButton) {
        performSegueWithIdentifier("generateCodeSegue", sender: self)
        trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_MAP_PAGE_CONNECT.rawValue, label: Label.COUNT.rawValue, value: nil)
    }
    
    func menuTapped(sender: UIButton) {
        performSegueWithIdentifier("showHelpSegue", sender: self)
        trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_MAP_PAGE_HELP.rawValue, label: Label.COUNT.rawValue, value: nil)
    }

    // regionFirstStart
    
    func regionFirstStart(manager: CLLocationManager) {
        if manager.monitoredRegions.count == 0 {
            let rg = CLCircularRegion(center: currentLocation!.coordinate, radius: defaultDistance, identifier: regionName)
            manager.startMonitoringForRegion(rg)
        }
    }
  
    
    //location delegate Methods 
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        currentLocation = newLocation
        updateLocation(manager, location: currentLocation) {}
        regionFirstStart(manager)
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
    
        currentLocation = locations.last
        
        //CLLocationDistance meters = [locations distanceFromLocation:oldLocation];
        
        regionFirstStart(manager)
        
        // stop monitoring for all regions
//        for region in manager.monitoredRegions {
//            manager.stopMonitoringForRegion(region)
//        }
//        
//        // add monitoring region
//        let rg = CLCircularRegion(center: currentLocation!.coordinate, radius: defaultDistance, identifier: regionName)
//        manager.startMonitoringForRegion(rg)
        
        
        
        let center = CLLocationCoordinate2D(latitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude)
        let regionMap = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.Map.setRegion(regionMap, animated: true)
        
        
        if firstUpdate == false {
            SwiftSpinner.show("Updating Location", animated: true)
            locationUpdateMode = LocationUpdateMode.Manual
          
            updateLocation(manager, location: currentLocation){
                SwiftSpinner.hide()
                if self.currentLocationString == "" {
                    let alert = UIAlertController(title: "Updated", message: "Your location has been updated.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else{
                    let alert = UIAlertController(title: "Updated", message: "Your location has been updated at \(self.currentLocationString)", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            firstUpdate = true
            restartLocationUpdate(false)
        }
        
        //Gets updated to server only if N minutes+ (Info.plist)
        if  Int(NSDate().timeIntervalSinceDate(lastUpdate)) > AppService.getLocationUpdateTimeSec() {
            
            SwiftSpinner.show("Updating Location", animated: true)
            
            locationUpdateMode = LocationUpdateMode.Alarm
            updateLocation(manager, location: currentLocation){
                SwiftSpinner.hide()

            }
            self.lastUpdate = NSDate()

        
        } else if  Int(NSDate().timeIntervalSinceDate(self.lastUpdate)) > 120 {
            
            btnTimeUpdated.setTitle("Updated \(Int(NSDate().timeIntervalSinceDate(lastUpdate))/60) minutes ago", forState: UIControlState.Normal)
        }
        
        if regionUpdate == false {
            
            SwiftSpinner.show("Updating Location", animated: true)
            
            locationUpdateMode = LocationUpdateMode.Region
            updateLocation(manager, location: currentLocation){
                SwiftSpinner.hide()
                
            }
            //self.lastUpdate = NSDate()
            let rg = CLCircularRegion(center: (currentLocation?.coordinate)!, radius: defaultDistance, identifier: regionName)
            manager.startMonitoringForRegion(rg)
            regionUpdate = true
        }
        
    }
    
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        manager.stopMonitoringForRegion(region)
        regionUpdate = false
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .AuthorizedWhenInUse:
            break
        case .AuthorizedAlways:
            break
        case .Restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            
            break
            
        case .Denied:
            // user denied your app access to Location Services, but can grant access from Settings.app
            // Create the alert controller
            trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_MAP_PAGE_DECLINED_LOCATION_ACCESS.rawValue, label: Label.STATUS.rawValue, value: nil)
            let alertController = UIAlertController(title: "Allow Location Access", message: "Allow GPS Tracker to access your location.", preferredStyle: .Alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (_) -> Void in
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                if let url = settingsUrl {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            
            // Add the actions
            alertController.addAction(settingsAction)
            
            // Present the controller
            self.presentViewController(alertController, animated: true, completion: nil)
            break

        }
    }
    
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        
        print("Error" + error.localizedDescription)
        Bugsnag.notify(NSException(name: "Location Monitoring Failed", reason: "Error + \(error.localizedDescription)", userInfo: nil))
    }
  
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
    }
    
    @IBAction func updateLocationTapped() {
        SwiftSpinner.show("Updating \nyour Location...", animated: true)
        trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_MAP_PAGE_CLICK.rawValue, label: Label.STATUS.rawValue, value: nil)
        restartLocationUpdate(true)
        firstUpdate = false
        trackEvent(Cateogary.MAP_PAGE.rawValue, action: Action.EVENT_MAP_PAGE_UPDATE_LOCATION.rawValue, label: Label.COUNT.rawValue, value: nil)
    }

    @IBAction func updateUserLocationOnMap(sender: AnyObject) {
        self.Map.showsUserLocation = true
    }
  
    func updateLocation(manager: CLLocationManager!, location: CLLocation!,completionHandler: ()->Void){
        
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
                        reverseGeoCodeAndSend(lastLoc, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: LocationUpdateMode.Missed)  {
                            (isError, error) -> Void  in
                            if isError {
                                print("Error Occurred while updating !")
                                self.logBugsnagServerError(LocationUpdateMode.Missed, error: error)
                                return
                            }
                            else {
                                 if locationDB.open(){
                                    let SQL = "DELETE FROM LOCATIONS WHERE UPDATED_TIME =?"
                                    _ = locationDB.executeUpdate (SQL, withArgumentsInArray: [updateTime])
                                    print("Deleted")
                                    completionHandler()
                                }
                                 else {
                                    print("Unable to open the DB")
                                    Bugsnag.notify(NSException(name: "FailureInOpeningDatabase", reason: "Error: \(locationDB.lastErrorMessage())", userInfo: nil ))
                                }
                            }
                        }
                    }
                    
                } else {
                    print("Error: \(locationDB.lastErrorMessage())")
                    Bugsnag.notify(NSException(name: "FailureInOpeningDatabase", reason: "Error: \(locationDB.lastErrorMessage())", userInfo: nil ))
                }
                
                let updateTime = NSDate().timeIntervalSince1970 * 1000
                let accuracy = location.horizontalAccuracy.description
                let device = UIDevice.currentDevice()
                device.batteryMonitoringEnabled = true
                let battery = Int(device.batteryLevel * 100)
                let mode = locationUpdateMode
                reverseGeoCodeAndSend(location, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: mode) {
                    (isError, error) -> Void  in
                    //Check if update was successful. if true the delete from table
                    if isError {
                        self.addToDB(locationDB, locationToStore: CurrentLocation(location: location))
                        self.logBugsnagServerError(mode, error: error)
                    }
                    
                    else {
                        completionHandler()
                        return
                    }
                    
                }
                
                locationDB.close()
                
            } else {
                addToDB(locationDB, locationToStore: locationToStore)
                print("Internet connection FAILED")
                SwiftSpinner.hide()
                let alertController = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "Ok", style: .Default ) { (action) in
                }
                alertController.addAction(cancelAction)
                
                
                self.presentViewController(alertController, animated: true) {
                    // ...
                }

                
            }
            return
        }
    
    
    func addToDB(locationDB : FMDatabase , locationToStore : CurrentLocation){
        
        if locationDB.open() {
            
            let insertSQL = "INSERT INTO LOCATIONS (FIELD_ACTIVITY, VERSION_NAME , LONGITUDE , LATITUDE , ACCURACY_LEVEL , BATTERY_STATUS , UPDATED_TIME , TIMEZOME , FULL_ADDRESS , REVERSE_GEO_STATUS , MODE ,COUNTRY_CODE, HASH_LOCATION, HASH_PRECISION) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)"

            print(locationToStore.getValuesOnly())
            
            let result = locationDB.executeUpdate(insertSQL, withArgumentsInArray: locationToStore.getValuesOnly())
            if !result {
                print("Error1: \(locationDB.lastErrorMessage())")
            } else {

            }
        } else {
            print("Error2: \(locationDB.lastErrorMessage())")
            
        }
        
        locationDB.close()
    }
    
    
    
    func reverseGeoCodeAndSend(location : CLLocation, updateTime : Double, accuracy : String, battery : Int, mode : LocationUpdateMode, completionHandler : (Bool, NSError?)->Void ){
        
        self.lastLocation=location;
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
                        self.firstUpdate = true
                        SwiftSpinner.hide()
                        
                        let name = pm.name ?? ""
                        let subAdministrativeArea = pm.subAdministrativeArea ?? ""
                        let administrativeArea = pm.administrativeArea ?? ""
                        let ISOcountryCode = pm.ISOcountryCode ?? ""
                        let country = pm.country ?? ""
                        
                        self.btnTimeUpdated.setTitle("Updated Just Now", forState: UIControlState.Normal)
                        self.btnLocationUpdated.setTitle("\(name), \(subAdministrativeArea),  \(administrativeArea), \(ISOcountryCode)",forState: UIControlState.Normal )
                        self.currentLocationString = String("\(name), \(subAdministrativeArea),  \(administrativeArea), \(country)")
                        //self.lastUpdate = NSDate()
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
    
}

