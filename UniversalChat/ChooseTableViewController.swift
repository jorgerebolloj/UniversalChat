//
//  ChooseTableViewController.swift
//  UniversalChat
//
//  Created by Jorge Rebollo J on 22/06/16.
//  Copyright © 2016 Pademobile International LLC. All rights reserved.
//

import UIKit
import Firebase

class ChooseTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchString = ""
    var searchInProgress = false
    
    var ref: FIRDatabaseReference!
    var chatrooms: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    private var _refHandle: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.delegate = self

        configureDatabase()
        configureStorage()
        configureRemoteConfig()
        fetchConfig()
        logViewLoaded()
    }
    
    deinit {
        self.ref.child("chatrooms").removeObserverWithHandle(_refHandle)
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.child("chatrooms").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            self.chatrooms.append(snapshot)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.chatrooms.count-1, inSection: 0)], withRowAnimation: .Automatic)
        })
    }
    
    func configureStorage() {
        storageRef = FIRStorage.storage().referenceForURL("gs://project-5790443035090996775.appspot.com")
    }
    
    func configureRemoteConfig() {
        remoteConfig = FIRRemoteConfig.remoteConfig()
        // Create Remote Config Setting to enable developer mode.
        // Fetching configs from the server is normally limited to 5 requests per hour.
        // Enabling developer mode allows many more requests to be made per hour, so developers
        // can test different config values during development.
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
    }
    
    func fetchConfig() {
        var expirationDuration: Double = 3600
        // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
        // the server.
        if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
            expirationDuration = 0
        }
        
        // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
        // fetched and cached config would be considered expired because it would have been fetched
        // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
        // throttling is in progress. The default expiration duration is 43200 (12 hours).
        remoteConfig.fetchWithExpirationDuration(expirationDuration) { (status, error) in
            if (status == .Success) {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
                let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
                if (friendlyMsgLength.source != .Static) {
                    self.msglength = friendlyMsgLength.numberValue!
                    print("Friendly msg length config: \(self.msglength)")
                }
            } else {
                print("Config not fetched")
                print("Error \(error)")
            }
        }
    }
    
    func logViewLoaded() {
        FIRCrashMessage("View loaded")
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchString = searchText
        searchInProgress = true
        //self.loadObjects()
        searchInProgress = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell = tableView.dequeueReusableCellWithIdentifier("chatRoomCell", forIndexPath: indexPath)

        // Unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.chatrooms[indexPath.row]
        let message = messageSnapshot.value as! Dictionary<String, String>
        let name = message[Constants.ChatRoomsFields.name] as String!
        if let imageUrl = message[Constants.ChatRoomsFields.imageUrl] {
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX){ (data, error) in
                    if let error = error {
                        print("Error downloading: \(error)")
                        return
                    }
                    cell.imageView?.image = UIImage.init(data: data!)
                }
            } else if let url = NSURL(string:imageUrl), data = NSData(contentsOfURL: url) {
                cell.imageView?.image = UIImage.init(data: data)
            }
            cell.textLabel?.text = "sent by: \(name)"
        } else {
            let text = message[Constants.ChatRoomsFields.text] as String!
            cell.textLabel?.text = name + ": " + text
            cell.imageView?.image = UIImage(named: "ic_account_circle")
            if let photoUrl = message[Constants.ChatRoomsFields.photoUrl], url = NSURL(string:photoUrl), data = NSData(contentsOfURL: url) {
                cell.imageView?.image = UIImage(data: data)
            }
        }

        return cell
    }
    
    func showAlert(title:String, message:String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: title,
                                          message: message, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .Destructive, handler: nil)
            alert.addAction(dismissAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
