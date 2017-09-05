//
//  ChatLogController.swift
//  InstantChat
//
//  Created by SUN YU on 14/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase


class ChatLogController:UICollectionViewController,UITextFieldDelegate,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    
    var user:User?
    {
        didSet
        {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    func observeMessages()
    {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        
        userMessagesRef.observe(.childAdded, with: {
            
            (snapshot) in
            
            
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: DataEventType.value, with: {
            
            (snapshot) in
                
                guard let dictionary = snapshot.value as? [String:AnyObject] else { return }

                let message = Message()
                message.setValuesForKeys(dictionary)
                
     
                self.messages.append(message)
                //this will crash because of background thread, so lets user dispatch_async to fix
                DispatchQueue.main.async(execute: { self.collectionView?.reloadData() })
             
                

            
            
            }, withCancel: nil)
        
        }, withCancel: nil)
    }
    
    lazy var inputTextField:UITextField = {
        
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
        
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 58, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true 
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        
        collectionView?.keyboardDismissMode = .interactive
        
        
        
        //setupInputComponents()
        
        //setupKeyboardObservers()
        
    }
    
    lazy var inputContainerView:UIView = {
       
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        
        let uploadImageView = UIImageView()
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.image = UIImage(named: "upload_Image")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))

        containerView.addSubview(uploadImageView)
        
        
        //x,y,w,h
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: UIControlEvents.touchUpInside)
        containerView.addSubview(sendButton)
        
        //X,y,width,heigh
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        containerView.addSubview(self.inputTextField)
        
        //x,y,width,height
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor,constant:8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        let seperatorLineView = UIView()
        seperatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        seperatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(seperatorLineView)
        
        //x,y,height,width
        seperatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        seperatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        seperatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        seperatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
        
    }()
    
    
    func handleUploadTap()
    {
        let imagePiCkerController = UIImagePickerController()
        
        imagePiCkerController.allowsEditing = true
        imagePiCkerController.delegate = self
        
        present(imagePiCkerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker:UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage
        {
            
            selectedImageFromPicker = editedImage
            
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage
        {
            selectedImageFromPicker = originalImage
            
        }else
        {
            print("Somethings go wrong")
        }
        
        if let seletedImage = selectedImageFromPicker
        {
            uploadToFirebaseStorageUsingImage(image: seletedImage)
        }
        
        dismiss(animated: true, completion: nil)
        
        
    }
    
    private func uploadToFirebaseStorageUsingImage(image:UIImage)
    {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2)
        {
            ref.putData(uploadData, metadata: nil, completion: {
            
            (metadata,error) in
                
                if error != nil
                {
                    print("Failed to upload image:",error)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString
                {
                    self.sendMessageWithImageUrl(imageUrl:imageUrl)
                }
                
            
            })
        }
 
    }
    
    
    private func sendMessageWithImageUrl(imageUrl:String)
    {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timestamp:NSNumber = Int(NSDate().timeIntervalSince1970) as NSNumber
        
        // includes name is not a good idea, coz name could be modified then change records become inefficency
        let values = ["imageUrl":imageUrl,"toId":toId,"fromId":fromId,"timestamp": timestamp as Any]
        childRef.updateChildValues(values){
            
            (error,ref) in
            
            if error != nil
            {
                print(error)
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessageRef.updateChildValues([messageId:1])
            
            
        }

    }
    
    override var inputAccessoryView: UIView?
    {
        get
        {
            
            return inputContainerView
        }
    }
    
    
    override var canBecomeFirstResponder: Bool
    {
        return true 
    }
    
//    func setupKeyboardObservers()
//    {
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
//        
//    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        
        //if we don't remove the notification will occure memory leak
        
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func handleKeyBoardWillShow(notification: Notification)
    {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewButtonAnchor?.constant = -(keyboardFrame?.height)!
        UIView.animate(withDuration: keyboardDuration!, animations: {
        
        self.view.layoutIfNeeded()
        
        
        })

    }
    
    func handleKeyBoardWillHide(notification: Notification)
    {
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewButtonAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!, animations: {
            
            self.view.layoutIfNeeded()
            
            
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        
        
        setupCell(cell: cell, message: message)

        
        
        
        if let text = message.text {
             cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
        }
       
        
        return cell
    }
    
    
    private func setupCell(cell:ChatMessageCell,message:Message)
    {
        if let profileImageUrl = self.user?.profileImageUrl
        {
          cell.profileImageView.loadImageUsingCachewithUrlString(urlString: profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl
        {
            cell.messageImageView.loadImageUsingCachewithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
            
        }else
        {
            cell.messageImageView.isHidden = true

        }
        
        if message.fromId == Auth.auth().currentUser?.uid
        {
            
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        }else
        {
            cell.bubbleView.backgroundColor  = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
    }
    
    
    //every time rotate the application
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height:CGFloat = 80
        
        //GET Estimate height
        if let text = messages[indexPath.item].text
        {
            height = estimateFrameForText(text: text).height + 20
        }
        
        
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text:String)->CGRect
    {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string:text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 16)], context: nil)
        
        
    }
    
    var containerViewButtonAnchor:NSLayoutConstraint?
    
//    func setupInputComponents()
//    {
//        let containerView = UIView()
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        containerView.backgroundColor = UIColor.white
//        
//        view.addSubview(containerView)
//        
//        //constraint anchors
//        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        
//        containerViewButtonAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        containerViewButtonAnchor?.isActive = true
//        
//        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        
//        
//        let sendButton = UIButton(type: .system)
//        sendButton.setTitle("Send", for: .normal)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.addTarget(self, action: #selector(handleSend), for: UIControlEvents.touchUpInside)
//        containerView.addSubview(sendButton)
//        
//        //X,y,width,heigh
//        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
//        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
//        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//        
//
//        containerView.addSubview(inputTextField)
//        
//        //x,y,width,height
//        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor,constant:8).isActive = true
//        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
//        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//        
//        
//        let seperatorLineView = UIView()
//        seperatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
//        seperatorLineView.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(seperatorLineView)
//        
//        //x,y,height,width
//        seperatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
//        seperatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
//        seperatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
//        seperatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
//        
//        
//        
//        
//    }
    
    func handleSend()
    {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timestamp:NSNumber = Int(NSDate().timeIntervalSince1970) as NSNumber
        // includes name is not a good idea, coz name could be modified then change records become inefficency
        let values = ["text":inputTextField.text!,"toId":toId,"fromId":fromId,"timestamp": timestamp as Any]
        childRef.updateChildValues(values){
            
            (error,ref) in
            
            if error != nil
            {
                print(error)
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessageRef.updateChildValues([messageId:1])
            
            
        }
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    
}
