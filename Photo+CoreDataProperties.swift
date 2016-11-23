//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by hovno on 14/11/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageUrl: String?
    @NSManaged public var image: NSData?
    @NSManaged public var pin: Pin?

}
