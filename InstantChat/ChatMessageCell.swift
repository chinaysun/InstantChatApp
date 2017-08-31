//
//  ChatMessageCell.swift
//  InstantChat
//
//  Created by SUN YU on 27/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit

class ChatMessageCell: UICollectionViewCell {
    
    let textView:UITextView = {
       
        let tv = UITextView()
        tv.text = "adadad"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        return tv
        
    }()
    
    
    static let blueColor = UIColor(r: 0, g: 137, b: 249)
    
    let bubbleView:UIView = {
       
        let view = UIView()
        view.backgroundColor = blueColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true 
        return view
        
    }()
    
    
    let profileImageView:UIImageView = {
       
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
        
    }()
    
    
    
    
    
    var bubbleWidthAnchor:NSLayoutConstraint?
    var bubbleViewRightAnchor:NSLayoutConstraint?
    var bubbleViewLeftAnchor:NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
        //x,y,w,h
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 8).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        
        
        
        //x,y,w,h
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor,constant:-8)
        bubbleViewRightAnchor?.isActive = true
        
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubbleViewLeftAnchor?.isActive = false
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        
        
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        
        //x,y,w,h
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
