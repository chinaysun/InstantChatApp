//
//  LoginController+handlers.swift
//  InstantChat
//
//  Created by SUN YU on 10/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase


extension LoginController:UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    func handleRegister()
    {
        
        guard let email = emailTextField.text,let password = passwordTextField.text, let name = nameTextField.text else {
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password, completion: {
            
            (user,error) in
            
            if error != nil
            {
                print(error)
                return
            }
            
            
            guard let userID = user?.uid else
            {
                return
            }
            
            //successfully authenticated user
            
            let imageName = NSUUID().uuidString
            
            // must have a child path
            let storageRef = Storage.storage().reference().child("profile_image").child("\(imageName).png")
            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!)
            {
                storageRef.putData(uploadData, metadata: nil, completion: {
                
                (metadata,error)
                    
                    in
                    
                    if error != nil
                    {
                        print(error)
                        return
                    }
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString
                    {
                        let values = ["name":name,"email":email,"profileImageUrl":profileImageUrl]
                    
                        self.registerUserIntoDatabseWithUID(uid: userID, values: values as [String : AnyObject])
                    }
                
                })
            }
            
            
            
            
           
            
        })
    }

    private func registerUserIntoDatabseWithUID(uid:String,values:[String:AnyObject])
    {
        let ref = Database.database().reference(fromURL: "https://instantchat-7e681.firebaseio.com/")
        let usersReference = ref.child("users").child(uid)

        usersReference.updateChildValues(values, withCompletionBlock: {
            
            (err,ref) in
            
            if err != nil
            {
                print(err)
                return
            }
            
            self.dismiss(animated: true, completion: nil)
            
        })
    }
    
    
    func handleSelectProfileImageView()
    {
        

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true, completion: nil)
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
            profileImageView.image = seletedImage
        }
        
        dismiss(animated: true, completion: nil)
        
        
    }
}
