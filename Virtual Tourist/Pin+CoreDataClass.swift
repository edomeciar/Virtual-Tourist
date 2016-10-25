//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Eduard Meciar on 20/10/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import Foundation
import CoreData
import MapKit


public class Pin: NSManagedObject, MKAnnotation {

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity: ent,insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        }else{
            fatalError("Unable to find entity Pin")
        }
        
    }
    
    public var coordinate: CLLocationCoordinate2D{
        get{
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
