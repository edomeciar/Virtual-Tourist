//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Eduard Meciar on 20/10/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    
    struct Keys {
        static let EntityName = "Photo"
        
        static let ImageUrl = "imageUrl"
        static let Image = "image"
        static let Pin = "pin"
    }
    
    convenience init(imageUrl: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent,insertInto: context)
            self.imageUrl = imageUrl
        }else{
            fatalError("Unable to find entity Photo")
        }
    }

}
