//
//  CurrentLocation.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 29/11/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit


struct CurrentLocation {
    var locationData : [String : AnyObject]
    let defaults = NSUserDefaults.standardUserDefaults()

    
    init(location : CLLocation , placemark: CLPlacemark , updateTime : Double , accuracy : String, battery : Int, mode : LocationUpdateMode){
        locationData = [String : AnyObject]()
        var addressString = String()

        let device = UIDevice.currentDevice()
        device.batteryMonitoringEnabled = true
        self.defaults.setObject(location.horizontalAccuracy, forKey: "GridLocateAccuracy")
        
        locationData["field_activity"] = "unknown"
        locationData["version_name"] = NSBundle.mainBundle().releaseVersionNumber
        locationData["longitude"] = location.coordinate.longitude
        locationData["latitude"] =  location.coordinate.latitude
        locationData["accuracy_level"] = accuracy
        locationData["battery_status"] = battery
        locationData["updated_time"] = updateTime

      
        locationData["timezone"] = ltzName()
        locationData["mode"] = mode.rawValue
        
        locationData["hash_location"] = Geohash.encode(latitude:location.coordinate.latitude , longitude:location.coordinate.longitude,10)
        locationData["hash_precision"] = 10

        
        if (placemark.addressDictionary != nil) {
            if (placemark.name != nil) {
                addressString  +=  placemark.name!.stringByReplacingOccurrencesOfString("\n", withString: "")
            }
            
            if (placemark.administrativeArea != nil) {
                
                addressString  += ", " + placemark.administrativeArea!
            }
            if (placemark.subAdministrativeArea != nil) {
                
                addressString  += ", " + placemark.subAdministrativeArea!
            }
            
            if (placemark.locality != nil) {
                addressString  += ", " + placemark.locality!
            }
            
            if (placemark.subLocality != nil) {
                addressString  += ", " + placemark.subLocality!
            }
            
            if (placemark.postalCode != nil) {
                addressString  += ", " + placemark.postalCode!
            }
            
            if (placemark.country != nil) {
                addressString  += ", " + placemark.country!
            }
            
            if(placemark.ISOcountryCode != nil){
                self.locationData["country_code"] = placemark.ISOcountryCode
            }
            self.locationData["full_address"] = addressString
            locationData["reverse_geo_status"] = 1
        } else {
            self.locationData["full_address"] = "null"
            locationData["reverse_geo_status"] = 0
        }
    }
    
    
    init( location : CLLocation ) {
        locationData = [String : AnyObject]()
        let device = UIDevice.currentDevice()
        device.batteryMonitoringEnabled = true

        locationData["field_activity"] = "unknown"
        locationData["version_name"] = NSBundle.mainBundle().releaseVersionNumber
        locationData["longitude"] = location.coordinate.longitude
        locationData["latitude"] =  location.coordinate.latitude
        locationData["accuracy_level"] = location.horizontalAccuracy
        locationData["battery_status"] = Int(device.batteryLevel * 100)
        locationData["updated_time"] = NSDate().timeIntervalSince1970 * 1000

        locationData["timezone"] = ltzName()
        locationData["full_address"] = "null"
        locationData["reverse_geo_status"] = 1
        locationData["mode"] = "fused"
        locationData["country_code"] = ""
        locationData["hash_location"] = "-1"
        locationData["hash_precision"] = -1
    }
    
    func ltzName() -> String { return NSTimeZone.localTimeZone().name }

    
    func getValuesOnly() -> [AnyObject] {
        
        var arr = [AnyObject]()
        
        arr.append(locationData["field_activity"] as! String)
        arr.append(locationData["version_name"] as! String)
        arr.append(locationData["longitude"] as! Double)
        arr.append(locationData["latitude"] as! Double)
        arr.append(locationData["accuracy_level"] as! Double)
        arr.append(locationData["battery_status"] as! Int)
        arr.append(locationData["updated_time"] as! Double)
        arr.append(locationData["timezone"] as! String)
        arr.append(locationData["full_address"] as! String)
        arr.append(locationData["reverse_geo_status"] as! Int)
        arr.append(locationData["mode"] as! String)
        arr.append(locationData["country_code"] as! String)
        arr.append(locationData["hash_location"] as! String)
        arr.append(locationData["hash_precision"] as! Int)
        
        return arr
    }
    
}