//
//  mainMapView.swift
//  Virtual Tourist
//
//  Created by Eduard Meciar on 19/10/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class mainMapView : UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var editLabelView: UIView!
    
    var editMode : Bool = false
    
    func setEditMode(editMode: Bool){
        self.editMode = editMode
        editLabelView.isHidden = !editMode
        if editMode{
            editButton.title = "Done"
        }else{
            editButton.title = "Edit"
        }
        print("edit mode set to: \(self.editMode)")
    }
    
    @IBAction func editButtonTouch(_ sender: AnyObject) {
        setEditMode(editMode: !editMode)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreMapRegion()
      
        //add long press action adding new pin
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(mainMapView.addPinLongPress(_:)))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        getPins()
    }
    
    var fetchedResultController: NSFetchedResultsController<Pin>!
    
    var filePathMapRegion : String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        return url.appendingPathComponent("mapRegion").path
    }
    
    
    func getPins(){
        let pinRequest = NSFetchRequest<Pin>(entityName: "Pin")
        let latitudeSort = NSSortDescriptor(key: "latitude", ascending: true)
        pinRequest.sortDescriptors = [latitudeSort]
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: pinRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do{
            try fetchedResultController.performFetch()
            if let pins = fetchedResultController.fetchedObjects as [Pin]? {
                print("Fetched pins")
                for pin in pins {
                    print("Pin lat: \(pin.latitude), Pin long: \(pin.longitude)")
                    mapView.addAnnotation(pin)
                }
            }
        }catch{
            fatalError("Fail to init FetchRequestPinController \(error)")
        }
        
    }
    
    var sharedContext: NSManagedObjectContext{
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        return stack.context
    }
    
    
    
   
    
    func addPinLongPress(_ gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let mapPin = Pin(latitude: newCoord.latitude, longitude: newCoord.longitude, context: sharedContext)
            print("New Pin lat: \(mapPin.latitude), Pin long: \(mapPin.longitude)")
            do{
                let delegate = UIApplication.shared.delegate as! AppDelegate
                try delegate.stack.save()
                print("Pin saved")
            }catch let error as NSError {
                print("Could not save \(error)")
            }
            
            mapView.addAnnotation(mapPin)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        let regionDictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelka" : mapView.region.span.longitudeDelta
        ]
        NSKeyedArchiver.archiveRootObject(regionDictionary, toFile: filePathMapRegion)
        print("mapView region changed")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let pin = view.annotation as! Pin
        if editMode{
            mapView.removeAnnotation(pin)
            sharedContext.delete(pin)
            print("Pin deleted")
        }else{
            performSegue(withIdentifier: "ShowPinPhotos", sender: pin)
        }
        
    }
    
    func restoreMapRegion(){
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: filePathMapRegion) as? [String:Any]{
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let latitudeDelata = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelata, longitudeDelta: longitudeDelta)
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            print("mapView resotred")
            mapView.setRegion(savedRegion, animated: true)
        }else{
            print("RegionDictionary don't exist")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPinPhotos"{
            let pin = sender as! Pin
            let photoAlbumView = segue.destination as! PhotoAlbumViewController
            photoAlbumView.mapPin = pin
            photoAlbumView.mapLatitudeDelta = mapView.region.span.latitudeDelta
            photoAlbumView.mapLongituteDelta = mapView.region.span.longitudeDelta
        }
    }
    
}
