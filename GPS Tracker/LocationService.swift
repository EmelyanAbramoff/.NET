//
//  ForecastService.swift
//  FlickFinder
//
//  Created by AnkitSingh on 29/11/15.
//  Copyright (c) 2015 ankitSingh. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON


enum LocationUpdateMode : String {
    case Manual  = "manual"
    case Region  = "region"
    case Alarm   = "timer"
    case Missed  = "missed"
}


struct LocationService {
    
    let  authToken : String
    let locationBaseURL : NSURL?
    let defaults = NSUserDefaults.standardUserDefaults()
    
    init(){
        authToken = ""
        locationBaseURL = NSURL(string: "https://api.gridlocate.com")
    }
    
    func addLocation(locationUpdate: CLLocation){
        //var location = CurrentLocation(location : locationUpdate)
        //To use for the offline addition of data
        
    }
    
    func sendRegistration( deviceName : String , completionHandler : (Bool? -> Void)){
        if let locationURL = NSURL(string: "/api/v1/registration", relativeToURL: locationBaseURL ){
            
            let networkOperation = NetworkOperation(url: locationURL )
            let device = Device(registeredName: deviceName)
            
            
            networkOperation.downloadJSONbyPOST(device.deviceData){
                (let json, let isError )in
            
                if isError == true {
                    print(json.error)
                    completionHandler(true)
                }
                
                if let token = json["auth_token"].string {
                    self.defaults.setObject(token, forKey: "GridLocateApiToken")
                    if let deviceId = json["user_name"].string {
                        self.defaults.setObject(deviceId, forKey: "GridLocateDeviceID")
                        completionHandler(false)
                    }
                }
                else{
                    completionHandler(true)
                }
                
            }
            
        } else {
            completionHandler(true)
            print("Could not Construct a valid URL")
        }
    }
    
    func sendLocationUpdate( location : CLLocation , placemark : CLPlacemark , updateTime : Double, accuracy : String, battery : Int, mode : LocationUpdateMode, completionHandler : (Bool, NSError?) -> Void){
        
        if let locationURL = NSURL(string: "/api/v1/location", relativeToURL: locationBaseURL ){
            
            let networkOperation = NetworkOperation(url: locationURL )
            let location = CurrentLocation(location: location, placemark: placemark, updateTime: updateTime, accuracy: accuracy, battery: battery, mode: mode)
            let token =  self.defaults.objectForKey("GridLocateApiToken") as! String
            
            networkOperation.downloadJSONbyPOSTwithToken(location.locationData, token: token ){
                (let json , let isError)in
                
                if isError == true {
                    
                    if json.error?.code == 999 {
                        let error = NSError(domain: "domain", code: 999, userInfo: ["error": "Not Found", "message": "Server not found"])
                        completionHandler(true, error)
                    } else {
                        completionHandler(true, json.error)
                    }
                    
                }
                else if let _ = json["insertId"].int {
                   completionHandler(false, nil)
                }
                else {
                    
                    if json["statusCode"].int >= 400 {
                        let error = NSError(domain: "domain", code: json["statusCode"].int!, userInfo: ["error":json["error"].description, "message":json["message"].description])
                        completionHandler(true, error)
                    } else {
                        completionHandler(true, json.error)
                    }

                }
            }
            
        } else {
            completionHandler(true, nil)
            print("Could not Construct a valid URL")
        }
    }

    
    // request of deviceID & password
    func getCode(completionHandler: (String , String, Double ) -> Void){
        
        if let locationURL = NSURL(string: "/api/v1/tempdetail", relativeToURL: locationBaseURL ){
            
            let networkOperation = NetworkOperation(url: locationURL )
            let token =  self.defaults.objectForKey("GridLocateApiToken") as! String
            
            networkOperation.sendGetWithTokenOnly(token) {
                (let json , let isError)in
                
                if isError == true{
                    print(json.error)
                    completionHandler("", "", 0)
                }
                
                if let deviceId = json["device_id"].string {
                    if let password = json["password"].string {
                        if let expiry = json["expiry_time"].double {
                            completionHandler(deviceId, password, expiry)
                        }
                    }
                }
                else {
                    completionHandler("", "", 0)
                }
            }
            
        } else {
            print("Could not Construct a valid URL")
        }
        
    }

    
    
}