//
//  SidebarViewController.swift
//  Estudy
//
//  Created by vsokoltsov on 04.11.15.
//  Copyright © 2015 vsokoltsov. All rights reserved.
//

import UIKit

let sidebarCell = "sidebarCell"
var sideBarMenu: [String]!
let authSideBarMenu = ["Messages"]

class SidebarViewController: ApplicationViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var signOutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "currentUserReceived:", name: "currentUser", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "currentUserReceived:", name: "signOut", object: nil)
        self.tableView.backgroundColor = UIColor.clearColor()
        self.view.backgroundColor = Constants.Colors.sidebarBackground
        setSidebarItems()
        
    }
    @IBOutlet var tableView: UITableView!
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(sidebarCell, forIndexPath: indexPath)
        let row = sideBarMenu[indexPath.row]
        cell.textLabel?.text = row
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = UIFont(name: "Avenir-Medium", size: 19.0)
        return cell
    }
    
    override func currentUserReceived(notification: NSNotification) {
        setSidebarItems()
        self.tableView.reloadData()
    }
    
    func setSidebarItems() {
        if (AuthService.sharedInstance.currentUser != nil) {
            sideBarMenu = ["Profile", "Messages"]
            signOutButton.hidden = false
        }
        else {
           sideBarMenu = ["Sign in", "Sign up"]
           signOutButton.hidden = true
        }
    }

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sideBarMenu.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch sideBarMenu[indexPath.row] {
            case "Sign in":
                self.performSegueWithIdentifier("authorization", sender: self)
            case "Sign up":
                self.performSegueWithIdentifier("registration", sender: self)
            case "Messages":
                self.performSegueWithIdentifier("chats", sender: self)
        default: break
            
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navVC = segue.destinationViewController as! UINavigationController
        if segue.identifier == "authorization" {
            let tableVC = navVC.viewControllers.first as! AuthorizationViewController
            tableVC.isAuth = true
        }
        
        if (segue.identifier == "registration") {
            let tableVC = navVC.viewControllers.first as! AuthorizationViewController
            tableVC.isAuth = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func signOut(sender: AnyObject) {
        AuthService.sharedInstance.signOut()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
