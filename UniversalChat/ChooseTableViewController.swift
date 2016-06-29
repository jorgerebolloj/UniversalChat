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
        //createModelData()
        
        /*let postRef = self.ref.child("posts")
        let post1 = ["author": "gracehop", "title": "Announcing COBOL, a New Programming Language"]
        let post1Ref = postRef.childByAutoId()
        post1Ref.setValue(post1)
        
        let post2 = ["author": "alanisawesome", "title": "The Turing Machine"]
        let post2Ref = postRef.childByAutoId()
        post2Ref.setValue(post2)*/
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
            print("\(self.chatRooms)")
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
            /*_refHandle = self.ref.child("chatrooms").queryOrderedByChild("fullName").queryEqualToValue("your full name").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    
                    }*/
            print(" search text: \(searchBar.text! as NSString)")
            searchInProgress = true
            self.filteredChatRoomsData = self.chatRoomsData.filter{
                let firstName = $0["name"]!!.lowercaseString
                //return (firstName.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch).location) != NSNotFound
                return firstName.rangeOfString(searchText.lowercaseString) != nil
            }
            print("filteredChatRoomsData: \(self.filteredChatRoomsData)")
            tableView.reloadData()
        }
    }
    
    /*func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        /*filteredChatRoomsData = chatRoomsData.filter ({ user in
            return user.model.lowercaseString.containsString(searchText.lowercaseString)
        })*/
        if(filtered.count == 0){
            searchInProgress = false;
        } else {
            searchInProgress = true;
        }
        self.tableView.reloadData()
    }*/
    
    /*func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.filtered = self.data.filter({( $0 as! String == "Test"
            let categoryMatch = (scope == "All") || (object.category == scope)
            let stringMatch = object.name.rangeOfString(searchText)
            return categoryMatch && (stringMatch != nil)
        })
    }*/
    
    /*func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        for userItem in chatRoomsDic {
            let newUser = Dictionary <String,String>(dictionaryLiteral:(name:(userItem.objectForKey("name")) as! String, text:(userItem.objectForKey("text")) as! String))
            self.data.append(newUser)
            
        }
        filtered = data.filter({ $0["name"] as! NSString == String
            let tmp: NSString = text as! NSString
            let range = tmp.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        })
        if(filtered.count == 0){
            searchInProgress = false;
        } else {
            searchInProgress = true;
        }
        self.tableView.reloadData()
    }*/
    
    //func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        /*if (searchText != "") {
            refHandle = self.ref.child("chatrooms").queryOrderedByChild("name").queryStartingAtValue(searchText).observeEventType(.ChildAdded, withBlock: { snapshot in
                // Get user value
                let username = snapshot.value!["username"] as! String
                let user = User.init(username: username)
                self.filtered.append(snapshot)
                
            }) { (error: NSError!) in
                
                print(error.localizedDescription)
                
                }/*
                { snapshot in
                print(snapshot.key)
            })*/
            searchString = searchText
        }*/
    //}

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
        return chatRoomsData.count
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
            print("filteredUser data cell: \(filteredUser)")
        } else {
            //let userSnapshot: FIRDataSnapshot! = self.chatRooms[indexPath.row]
            //let user = userSnapshot.value as! Dictionary<String, String>
            let user = chatRoomsData[indexPath.row] as! Dictionary<String, String>
            print("userSnapshot: \(user)")
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
            print("user data cell: \(user)")
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
