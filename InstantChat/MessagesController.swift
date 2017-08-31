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

    
    let cellId = "cellId"
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        
        let image = UIImage(named: "new_messages_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        

    }
    
    var messages = [Message]()
    var messagesDictionary = [String:Message]()
    
    func observeUserMessages()
    {
        guard let uid = Auth.auth().currentUser?.uid else
        {
            return
        }
        
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        
        ref.observe(DataEventType.childAdded, with: {
        
        (snapshot)
            
            in
            
            let messageId = snapshot.key
            let messageReference = Database.database().reference().child("messages").child(messageId)
            
            messageReference.observeSingleEvent(of: DataEventType.value, with: {
            
            (snapshot)
                
                in
                
            if let dictionary = snapshot.value as? [String:AnyObject]
            {
                let message = Message()
                message.setValuesForKeys(dictionary)
                    
                if let chatPartnerId = message.chatPartnerId()
                {
                        
                    self.messagesDictionary[chatPartnerId] = message
                    self.messages = Array(self.messagesDictionary.values)
                    self.messages.sort(by: {
                            
                        (message1,message2) -> Bool
                        in
                            
                        return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
                            
                    })
                }
                
                
                //countine to cancel the timer until the last
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
                
                    
           
            }
                

                
            
            }, withCancel: nil)
            
        
        }, withCancel: nil)
    }
    
    var timer:Timer?
    
    func handleReloadTable()
    {
        //this will crash because of background thread, so lets user dispatch_async to fix
        DispatchQueue.main.async(execute: { self.tableView.reloadData() })
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else
        {
            return
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        
        ref.observeSingleEvent(of: DataEventType.value, with: {
        
        (snapshot)
            
            in
            
            guard let dictionary = snapshot.value as? [String:AnyObject] else { return }
            
            let user = User()
            user.id = chatPartnerId
            user.setValuesForKeys(dictionary)
            self.showChatControllerForUser(user: user)
            
        
        }, withCancel: nil)
        
    }
    
    
    func handleNewMessage()
    {
        let newMessageController = NewMessageController()
        newMessageController.messageController = self
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
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle()
    {
        guard let uid = Auth.auth().currentUser?.uid else {
            
            //for some reason uid = nil
            return
        }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: DataEventType.value , with: {
            
            (snapshot) in
            
            if let dictionary = snapshot.value as? [String:AnyObject]
            {
                
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user: user)
            }
            
            
        }, withCancel: nil)
    }
    
    
    func setupNavBarWithUser(user:User)
    {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        
        //third view to make the titleview fill out the space
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        
        if let profileImageUrl = user.profileImageUrl
        {
            profileImageView.loadImageUsingCachewithUrlString(urlString: profileImageUrl)

        }
        
        containerView.addSubview(profileImageView)
        
        //need x,y,width,height anchors
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabel)
        
        //need x,y,width, height
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        
        self.navigationItem.titleView = titleView
        
        
        //titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        
    }
    
    func showChatControllerForUser(user:User)
    {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
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
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
        
    }



}

