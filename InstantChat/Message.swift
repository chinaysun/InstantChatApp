//
//  Message.swift
//  InstantChat
//
//  Created by SUN YU on 15/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {

    var fromId:String?
    var text:String?
    var timestamp:NSNumber?
    var toId:String?
    
    
    var imageUrl:String?
    
   func chatPartnerId() -> String? {
    
     return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    
   }
    
  
}
