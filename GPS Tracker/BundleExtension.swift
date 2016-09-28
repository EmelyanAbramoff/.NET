//
//  BundleExtension.swift
//  GPS Tracker
//
//  Created by DP singh on 18/12/15.
//  Copyright © 2015 gridlocate. All rights reserved.
//

import Foundation
extension NSBundle {
    
    var releaseVersionNumber: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return self.infoDictionary?["CFBundleVersion"] as? String
    }
    
}