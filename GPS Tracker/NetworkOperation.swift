//
//  NetworkOperation.swift
//  FlickFinder
//
//  Created by AnkitSingh on 29/11/15.
//  Copyright (c) 2015 ankitSingh. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Bugsnag

class NetworkOperation {
    
    lazy var configuration : NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session : NSURLSession = NSURLSession(configuration: self.configuration)
    let queryURL : NSURL
    
    typealias JSONCompletion = ((JSON, Bool) -> Void)
    
    init(url : NSURL){
        queryURL = url
    }
    
    
    func downloadJSONbyPOST(device : [String : AnyObject] , completionHandler : JSONCompletion) {

        Alamofire.request(.POST, queryURL , parameters: device , encoding: .JSON)
            .responseJSON { response in
                switch response.result {
                case .Success(let data):
                    let json = JSON(data)
                    print(data)
                    completionHandler(json, false)
                case .Failure(let error):
                    Bugsnag.notify(NSException(name: "FailureInRegistration", reason: "Unsuccessful response while Registering", userInfo: nil))
                    completionHandler( JSON(error), true)
                    
                }
        }
        
    }
    
    
    //POST with header of bearer auth
    
    func downloadJSONbyPOSTwithToken(location : [String : AnyObject] , token: String , completionHandler : JSONCompletion) {

        //Add token to the header
        let headers = [
            "Authorization": "Bearer "+token,
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        // logging
        if let mode = location["mode"] {
            print("Updating mode: \(mode)")
        }
        
        Alamofire.request(.POST, queryURL , headers: headers,  parameters: location , encoding: .JSON)
            .responseJSON {
                response in
                print(response);
                switch response.result {
                case .Success(let data):
                    print(JSON(data))
                    
                    if let mode = location["mode"] {
                        
                        do {
                            let notifData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.PrettyPrinted)
                            
                            let notificationText = (mode as? String)!  + (NSString(data: notifData, encoding: NSUTF8StringEncoding)! as String)
                                    if AppService.isLocationUpdateLoggingNotification() {
                            let notification = UILocalNotification()
                            notification.alertBody = notificationText
                            notification.fireDate = NSDate()
                                        UIApplication.sharedApplication().scheduleLocalNotification(notification)
                            }
                        } catch {
                            
                        }
                        
    
                    }
                    
                    completionHandler( JSON(data),false)
                case .Failure(let error):
                    Bugsnag.notify(NSException(name: "FailureInLocationUpdate", reason: "Unsuccessful response while Updating Locaton", userInfo: nil))
                    completionHandler( JSON(error), true)
                }
        }
        
    }
    
    
    func sendGetWithTokenOnly( token : String , completionHandler : JSONCompletion){
        
        let headers = [
            "Authorization": "Bearer "+token,
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        Alamofire.request(.GET, queryURL , headers: headers , encoding: .JSON)
            .responseJSON { response in
                switch response.result {
                case .Success(let data):
                    let json = JSON(data)
                    print(json)
                    completionHandler(json,false)
                case .Failure(let error):
                    Bugsnag.notify(NSException(name: "FailureInGettingCode", reason: "Unsuccessful response while fetching Code", userInfo: nil))
                    completionHandler( JSON(error), true)
                }
        }
    }

}