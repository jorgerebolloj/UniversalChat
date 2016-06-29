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
    var chatRooms: [FIRDataSnapshot]! = []
    var chatRoomsData: [AnyObject] = []
    var filteredChatRoomsData: [AnyObject] = []
    var msglength: NSNumber = 10
    private var _refHandle: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.delegate = self

        configureDatabase()
        configureStorage()
        configureRemoteConfig()
        fetchConfig()
        logViewLoaded()
        
        /*let postRef = self.ref.child("posts")
        let post1 = ["author": "gracehop", "title": "Announcing COBOL, a New Programming Language"]
        let post1Ref = postRef.childByAutoId()
        post1Ref.setValue(post1)*/
    }
    
    deinit {
        self.ref.child("chatrooms").removeObserverWithHandle(_refHandle)
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        self.chatRooms.removeAll()
        _refHandle = self.ref.child("chatrooms").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            self.chatRooms.append(snapshot)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.chatRooms.count-1, inSection: 0)], withRowAnimation: .Automatic)
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
    
    func createModelData() {
        self.chatRoomsData.removeAll()
        //create Modeldata to filter
        for user in self.chatRooms {
            let userSnapshot: FIRDataSnapshot! = user
            let userData = userSnapshot.value as! Dictionary<String, String>
            
            let name = userData[Constants.ChatRoomsFields.name] as String!
            let text = userData[Constants.ChatRoomsFields.text] as String!
            let photoUrl = userData[Constants.ChatRoomsFields.photoUrl] as String!
            let imageUrl = userData[Constants.ChatRoomsFields.imageUrl] as String!
            
            var dict = [String: String]()
            dict["name"] = name
            dict["text"] = text
            dict["photoUrl"] = photoUrl
            dict["imageUrl"] = imageUrl
            self.chatRoomsData.append(dict)
            print("Modeldata to filter: \(self.chatRoomsData)")
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchInProgress = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchInProgress = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchInProgress = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchInProgress = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String){
        if searchBar.text!.isEmpty{
            searchInProgress = false
            tableView.reloadData()
        } else {
            print(" search text: \(searchBar.text! as NSString)")
            searchInProgress = true
            createModelData()
            self.filteredChatRoomsData = self.chatRoomsData.filter {
                let firstName = $0["name"]!!.lowercaseString
                return firstName.rangeOfString(searchText.lowercaseString) != nil
            }
            print("filteredChatRoomsData: \(self.filteredChatRoomsData)")
            tableView.reloadData()
        }
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
        if(searchInProgress) {
            return filteredChatRoomsData.count
        }
        return chatRooms.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell = tableView.dequeueReusableCellWithIdentifier("chatRoomCell", forIndexPath: indexPath)

        // Unpack message from Firebase DataSnapshot
        if (searchInProgress) {
            let filteredUser = filteredChatRoomsData[indexPath.row] as! Dictionary<String, String>
            let userName = filteredUser[Constants.ChatRoomsFields.name] as String!
            let userText = filteredUser[Constants.ChatRoomsFields.text] as String!
            cell.textLabel?.text = userName + ": " + userText
            cell.imageView?.image = UIImage(named: "ic_account_circle")
            /*
             if let photoUrl = message[Constants.ChatRoomsFields.photoUrl], url = NSURL(string:photoUrl), data = NSData(contentsOfURL: url) {
             cell.imageView?.image = UIImage(data: data)
             }
             */
        } else {
            let userSnapshot: FIRDataSnapshot! = self.chatRooms[indexPath.row]
            let user = userSnapshot.value as! Dictionary<String, String>
            let name = user[Constants.ChatRoomsFields.name] as String!
            if let imageUrl = user[Constants.ChatRoomsFields.imageUrl] {
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
                let text = user[Constants.ChatRoomsFields.text] as String!
                cell.textLabel?.text = name + ": " + text
                cell.imageView?.image = UIImage(named: "ic_account_circle")
                if let photoUrl = user[Constants.ChatRoomsFields.photoUrl], url = NSURL(string:photoUrl), data = NSData(contentsOfURL: url) {
                    cell.imageView?.image = UIImage(data: data)
                }
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
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
}
