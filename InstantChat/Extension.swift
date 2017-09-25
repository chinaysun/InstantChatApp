//
//  Extension.swift
//  InstantChat
//
//  Created by SUN YU on 11/8/17.
//  Copyright © 2017 SUN YU. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView
{
    
    func loadImageUsingCachewithUrlString(urlString:String)
    {
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage
        {
            self.image = cachedImage
            return
        }
        
        
        //otherwise download the image
        let url = URL(string: urlString)
        
        URLSession.shared.dataTask(with: url!, completionHandler: {
            
            (data,response,error)
            
            in
            
            if error != nil
            {
                print(error)
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!)
                {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                }
                
                self.image = UIImage(data: data!)
            
            
            })
            
            
            
        }).resume()
    }
    
}

extension UIColor
{
    convenience init(r:CGFloat,g:CGFloat,b:CGFloat)
    {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}

