//
//  ViewController.swift
//  InstantChat
//
//  Created by SUN YU on 9/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UITableViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        
        //user is not logged in
        if Auth.auth().currentUser?.uid == nil
        {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
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

