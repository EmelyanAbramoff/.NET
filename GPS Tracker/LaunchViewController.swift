//
//  LaunchViewController.swift
//  GPS Tracker
//
//  Created by AnkitSingh on 06/12/15.
//  Copyright (c) 2015 gridlocate. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController, BWWalkthroughViewControllerDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var walkthroughshown = false

    override func viewDidAppear(animated: Bool) {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        
        if self.defaults.stringForKey("GridLocateApiToken") != nil || walkthroughshown == true {
         
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("navCtrl") as! UINavigationController
            self.presentViewController(nextViewController, animated:true, completion:nil)
            
            
        } else {
            showWalkthrough()
            
//                let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("navCtrl") as! UINavigationController
//                self.presentViewController(nextViewController, animated:true, completion:nil)

            
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trackScreen("welcome-page")

        // Do any additional setup after loading the view.
        activityIndicator.startAnimating()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        
    }
    

    func showWalkthrough(){
        
        // Get view controllers and build the walkthrough
        let stb = UIStoryboard(name: "Main", bundle: nil)
        let walkthrough = stb.instantiateViewControllerWithIdentifier("walk") as! BWWalkthroughViewController
        let page_zero = stb.instantiateViewControllerWithIdentifier("walk0") 
        let page_one = stb.instantiateViewControllerWithIdentifier("walk1") 
        
        
        // Attach the pages to the master
        walkthrough.delegate = self
        walkthrough.addViewController(page_zero)
        walkthrough.addViewController(page_one)
        
        
        self.presentViewController(walkthrough, animated: true, completion: nil)
        walkthroughshown = true
        //completionHandler()
    }
    
    func walkthroughPageDidChange(pageNumber: Int) {
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
