//
//  NewMessageControllerTableViewController.swift
//  InstantChat
//
//  Created by SUN YU on 10/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    
    let cellId = "cellId"
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    
    func fetchUser()
    {
        Database.database().reference().child("users").observe(DataEventType.childAdded, with: {
        
        (snapshot) in
            
            if let dictionary = snapshot.value as? [String:AnyObject]
            {
                let user = User()
                user.id = snapshot.key
                
                //if you use this setter, your app will crash if your class properties don't exactly match up with firebase dictionary keys
                user.setValuesForKeys(dictionary)
                self.users.append(user)
                
                //this will crash because of background thread, so lets user dispatch_async to fix
                DispatchQueue.main.async(execute: { self.tableView.reloadData() })
                
                
            }
        
        
        }, withCancel: nil)
        
        
    }
    
    func handleCancel()
    {
       self.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        
        if let profileImageUrl = user.profileImageUrl
        {
            cell.profileImageView.loadImageUsingCachewithUrlString(urlString: profileImageUrl)
            
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messageController:MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.dismiss(animated: true, completion: {
            
           let user = self.users[indexPath.row]
            
           self.messageController?.showChatControllerForUser(user: user)
        
        
        })
    }
    

}





