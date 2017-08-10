//
//  ViewController.swift
//  InstantChat
//
//  Created by SUN YU on 9/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        
        let image = UIImage(named: "new_messages_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()

    }
    
    func handleNewMessage()
    {
        let newMessageController = NewMessageController()
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn()
    {
        //user is not logged in
        if Auth.auth().currentUser?.uid == nil
        {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }else
        {
            let uid = Auth.auth().currentUser?.uid
            
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: DataEventType.value , with: {
            
            (snapshot) in
                
                if let dictionary = snapshot.value as? [String:AnyObject]
                {
                    self.navigationItem.title = dictionary["name"] as? String
                }
            
            
            }, withCancel: nil)
        }
    }
    
    func handleLogout()
    {
        do
        {
            try Auth.auth().signOut()
        }catch let logoutError
        {
            print(logoutError)
        }
        
        
        let loginController = LoginController()
        
        present(loginController, animated: true, completion: nil)
        
    }



}

