//
//  GoogleAnalyticsTracker.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 20/12/15.
//  Copyright © 2015 gridlocate. All rights reserved.
//

import Foundation

extension UIViewController {
    func trackScreen(name: String) {
        self.sendScreenView(name)
    }
    
    func sendScreenView(name : String) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: self.title)
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
        let tracker = GAI.sharedInstance().defaultTracker
        let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value)
        tracker.send(trackDictionary.build() as [NSObject : AnyObject])
    }
    
    enum Cateogary : String {
        case WALK_THROUGH = "walk_through"
        case REGISTRATION = "registration"
        case WELCOME = "welcome"
        case MAP_PAGE = "map_page"
        case CONNECT_PAGE = "connect_page"
    }
    
    enum Action : String {
        case EVENT_GET_STARTED = "event_get_started"
        case EVENT_WALK_THROUGH_NEXT = "event_walk_through_next"
        case EVENT_REGISTRATION_SUCCESS = "event_registration_success"
        case EVENT_REGISTRATION_FAILED = "event_registration_failed"
        case EVENT_MAP_PAGE_UPDATE_LOCATION = "event_map_page_update_location"
        case EVENT_MAP_PAGE_HELP = "event_map_page_help"
        case EVENT_MAP_PAGE_CONNECT = "event_map_page_connect"
        case EVENT_MAP_PAGE_SHARE = "event_map_page_share"
        case EVENT_MAP_PAGE_CLICK = "event_map_page_click"
        case EVENT_MAP_PAGE_DECLINED_LOCATION_ACCESS = "event_map_page_declined_location_access"
        case EVENT_CONNECT_PAGE_SHARE = "event_connect_page_share"
        case EVENT_CONNECT_PAGE_NEW_CODE = "event_connect_page_new_code"
        
    }
    
    enum Label : String {
        case INVITE_COUNT = "invite_count"
        case STATUS = "status"
        case COUNT = "count"
        case TBD = "TBD"
    }
    
    enum value {
        
    }
}


