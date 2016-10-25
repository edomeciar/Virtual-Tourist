//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Eduard Meciar on 20/10/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import Foundation
import CoreData 

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageUrl: String?
    @NSManaged public var pin: Pin?

}
