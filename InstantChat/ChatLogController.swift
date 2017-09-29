//
//  ChatLogController.swift
//  InstantChat
//
//  Created by SUN YU on 14/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation


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

                self.messages.append(Message(dictionary: dictionary))
                //this will crash because of background thread, so lets user dispatch_async to fix
                DispatchQueue.main.async(execute: {
                    
                    self.collectionView?.reloadData()
                
                //scroll to the last index
                    
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                
                
                })
             
                

            
            
            }, withCancel: nil)
        
        }, withCancel: nil)
    }
    

    
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
        
        setupKeyboardObservers()
        
    }
    
    lazy var inputContainerView:ChatInputContainerView = {
       
        let chatInputContainerView = ChatInputContainerView(frame:  CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    
    }()
    
    
    func handleUploadTap()
    {
        let imagePiCkerController = UIImagePickerController()
        
        imagePiCkerController.allowsEditing = true
        imagePiCkerController.delegate = self
        imagePiCkerController.mediaTypes = [kUTTypeImage as String,kUTTypeMovie as String]
        
        
        present(imagePiCkerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL
        {
            
            //we selected a video
            handleVideoSelectedForUrl(url: videoUrl)
            
        }else
        {
            //selected an image
            handleImageSelectedForInfo(info: info)
        }
        
    
        dismiss(animated: true, completion: nil)
        
        
    }
    
    private func handleVideoSelectedForUrl(url:URL)
    {
        let filename = NSUUID().uuidString + ".mov"
        
        
        let uploadTask = Storage.storage().reference().child("message_moive").child(filename).putFile(from: url, metadata: nil, completion: {
            
            (metadata,error) in
            
            if error != nil
            {
                print("Failed upload of video:" , error)
                return
            }
            
            if let storageUrl = metadata?.downloadURL()?.absoluteString
            {
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url)
                {
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: {
                    
                    (imageUrl) in
                        
                        
                        let properties = ["imageUrl":imageUrl,
                                          "imageWidth":thumbnailImage.size.width,
                                          "imageHeight":thumbnailImage.size.height,
                                          "videoUrl":storageUrl] as [String : AnyObject]
                        self.sendMessageWithProperties(properties: properties)
                        
                    })
                    
                    


                }
                
                
                
            }
            
            
            
        })
        
        uploadTask.observe(.progress, handler: {
        
        (snapshot) in
            
            if let completedUnitCount = snapshot.progress?.completedUnitCount
            {
                self.navigationItem.title = String(completedUnitCount)
            }
        
        
        
        })
        
        uploadTask.observe(.success, handler: {
        
        
        (snapshot) in
            
            self.navigationItem.title = self.user?.name
        
        
        })
        
    }
    
    
    private func thumbnailImageForFileUrl(fileUrl:URL) -> UIImage?
    {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do
        {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1,60), actualTime: nil)

            return UIImage(cgImage: thumbnailCGImage)
            
        }catch let err
        {
            print(err)
        }
        
        return nil
        
    }
    
    private func handleImageSelectedForInfo(info:[String : Any])
    {
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
        
        if let selectedImage = selectedImageFromPicker
        {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: {
            
            (imageUrl) in
                
                
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            
            
            
            })
        }
    }
    
    
    private func uploadToFirebaseStorageUsingImage(image:UIImage, completion: @escaping (String)->())
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
                    completion(imageUrl)
                }
                
            
            })
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
    
    func setupKeyboardObservers()
    {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    
    func handleKeyboardDidShow()
    {
        if messages.count > 0
        {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.bottom, animated: true)
        }

    }
    
    
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
        
        
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        cell.textView.text = message.text
        
        
        setupCell(cell: cell, message: message)

        
        if let text = message.text {
             cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
             cell.textView.isHidden = false
        }else if message.imageUrl != nil
        {
            //fall in here if its an image message
            
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        
        }
       
        cell.playButton.isHidden = message.videoUrl == nil
        
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
        
        let message = messages[indexPath.item]
        
        if let text = message.text
        {
            height = estimateFrameForText(text: text).height + 20
        }else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue
        {
            //h1 / w1 = h2 / w2
            height = CGFloat(imageHeight / imageWidth * 200)
      
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
        let properties = ["text":inputContainerView.inputTextField.text!] as [String:AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithImageUrl(imageUrl:String,image:UIImage)
    {
        let properties = ["imageUrl":imageUrl,"imageWidth":image.size.width,"imageHeight":image.size.height] as [String : AnyObject]
        sendMessageWithProperties(properties: properties)
        
    }
    
    private func sendMessageWithProperties(properties:[String:AnyObject])
    {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timestamp:NSNumber = Int(NSDate().timeIntervalSince1970) as NSNumber
        
        // includes name is not a good idea, coz name could be modified then change records become inefficency
        var values = ["toId":toId,"fromId":fromId,"timestamp": timestamp as Any]
        
        //append properties dictionary onto values key $0 value $1
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values){
            
            (error,ref) in
            
            if error != nil
            {
                print(error)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessageRef.updateChildValues([messageId:1])
            
            
        }
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView:UIView?
    var startingImageView:UIImageView?
    
    // my custom zooming logic
    func performZoomInForStartingImageView(startingImageView:UIImageView)
    {
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow
        {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                
                
                let height = (self.startingFrame?.height)! / (self.startingFrame?.width)! * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width , height: height)
                
                zoomingImageView.center = keyWindow.center

                
                
            }, completion:nil)
            
        }

        
    }
    
    func handleZoomOut(tapGesture:UITapGestureRecognizer)
    {
        if let zoomOutImageView = tapGesture.view
        {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true 
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            
            }, completion: {  (completed:Bool) in
                
                //
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            
            
            })
            
        }
    }
    
    
}
