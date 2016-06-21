//
//  LoginSignUpViewController.swift
//  UniversalChat
//
//  Created by Jorge Rebollo J on 17/06/16.
//  Copyright © 2016 Pademobile International LLC. All rights reserved.
//

import UIKit
import Firebase

class LoginSignUpViewController: UIViewController {
    
    @IBAction func loginDidTouch(sender: AnyObject) {
        /*ref.authAnonymouslyWithCompletionBlock { (error, authData) in // 1
        if error != nil { print(error.description); return } // 2
            self.performSegueWithIdentifier("LoginToChat", sender: nil) // 3
        }*/
        print("Login")
        self.performSegueWithIdentifier("ChatViewController", sender: nil)
    }

}
