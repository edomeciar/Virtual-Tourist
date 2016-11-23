//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Eduard Meciar on 25/10/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var detailMapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var mapPin: Pin!
    var mapLatitudeDelta: CLLocationDegrees!
    var mapLongituteDelta: CLLocationDegrees!
    
    var sharedContext: NSManagedObjectContext{
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        return stack.context
    }
    
    private func saveContext(){
        do{
            let delegate = UIApplication.shared.delegate as! AppDelegate
            try delegate.stack.save()
            print("context saved ")
        }catch let error as NSError {
            print("context NOT saved \(error)")
        }
    }
    
    var selectedPhotos: [Photo]? {
        didSet {
            print("added item to selectedPhotos, count: \(selectedPhotos?.count)")
            if selectedPhotos == nil || selectedPhotos!.count == 0 {
                newCollectionButton.title = "New Collection"
            } else {
                newCollectionButton.title = "Remove Selected Pictures"
            }
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = { () -> NSFetchedResultsController<Photo> in
        
        let fetchRequest = NSFetchRequest<Photo>(entityName: Photo.Keys.EntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.ImageUrl , ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.mapPin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    @IBAction func newButtonSent(_ sender: Any) {
        if selectedPhotos == nil || selectedPhotos!.count == 0 {
            print("delete all photos for Pin")
            for photo in (fetchedResultsController.fetchedObjects )! {
                sharedContext.delete(photo)
                print("delete photo \(photo.imageUrl)")
                self.saveContext()
            }
            getNewImages()
            self.photosCollectionView.reloadData()
        }else{
            print("pictures to delete: \(selectedPhotos!.count)")
            for selectedPhoto in selectedPhotos! {
                let photo = selectedPhoto
                sharedContext.delete(photo)
                print("delete photo \(photo.imageUrl)")
                self.saveContext()
            }
            selectedPhotos = nil
        }
        
    }
    
    
    
    func getNewImages(){
        print("New Collection")
        if FlickrClient.isCoordinateInRange(coordinate: mapPin.latitude, forRange: Constants.Flickr.SearchLatRange) && FlickrClient.isCoordinateInRange(coordinate: mapPin.longitude, forRange: Constants.Flickr.SearchLonRange) {
            let methodParameters = [
                Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                Constants.FlickrParameterKeys.BoundingBox: FlickrClient.bboxString(latitude: mapPin.latitude, longitude: mapPin.longitude),
                Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
                Constants.FlickrParameterKeys.Per_page : Constants.FlickrParameterValues.Per_page
            ]
            
            FlickrClient.sharedInstance().displayImageFromFlickrBySearch(methodParameters: methodParameters as [String : AnyObject], completitionHandler: { (photoArray, errorString) in
                print("starting processing photo data")
                if errorString == nil{
                    if let photos = photoArray as [[String: AnyObject?]]? {
                        print("getPhotoForPin photo array count\(photoArray?.count)")
                        for photo in photos{
                            if let photoUrl = photo["url_m"] as? String {
                                
                                let photo = Photo(imageUrl: photoUrl, context: self.sharedContext)
                                let imageURL = NSURL(string: photoUrl)
                                if let imageData = NSData(contentsOf: imageURL! as URL) {
                                    photo.image = imageData
                                    
                                } else {
                                    print("Image does not exist at \(imageURL)")
                                }
                                photo.pin = self.mapPin
                                self.saveContext()
                            }
                        }
                        
                    }
                    DispatchQueue.main.async {
                        self.photosCollectionView.reloadData()
                    }
                }else{
                    print(errorString)
                }
                
                
            })
        }
        else {
            print("Lat should be [-90, 90].\nLon should be [-180, 180].")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("photo selected")
        if let photo = fetchedResultsController.object(at: indexPath) as? Photo{
            let cell = photosCollectionView.cellForItem(at: indexPath)!
            if selectedPhotos == nil {
                selectedPhotos = [photo]
                cell.contentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
                cell.isHighlighted = true
                cell.isSelected = true
                photosCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
            }else{
                var found = -1
                for i in 0 ..< selectedPhotos!.count {
                    if photo === selectedPhotos![i] {
                        found = i
                        break
                    }
                }
                if found == -1 {
                    // item is not selected yet, let's add it to the array and highlight it
                    selectedPhotos!.append(photo)
                    cell.contentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
                    cell.isHighlighted = true
                    cell.isSelected = true
                    photosCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
                } else {
                    // selected item is tapped again, remove it from the array and unhighlight it
                    selectedPhotos!.remove(at: found)
                    cell.contentView.backgroundColor = nil
                    cell.isHighlighted = false
                    cell.isSelected = false
                    photosCollectionView.deselectItem(at: indexPath, animated: false)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setFlowLayout()
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        detailMapView.addAnnotation(mapPin)
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        let region = MKCoordinateRegion(center: mapPin.coordinate, span: span)
        detailMapView.setRegion(region, animated: true)
    }
    
    func setFlowLayout() {
        let space: CGFloat = 3.0
        var dimension: CGFloat = 0.0
        
        if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
            dimension = (self.view.frame.size.width - (5 * space)) / 6.0
        }
        
        if(UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        }
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    
    //UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        
        if let photo = fetchedResultsController.object(at: indexPath) as? Photo {
            if let imageData = photo.image{
                print("Photo wiht image data")
                let image = UIImage(data: imageData as Data)
                let imageView = UIImageView(image: image)
                DispatchQueue.main.async {
                    cell.backgroundView = imageView
                    cell.activityIndicator.stopAnimating()
                }
            }else if photo.imageUrl == nil || photo.imageUrl == "" {
                print("Photo without image URL")
                DispatchQueue.main.async {
                    cell.activityIndicator.stopAnimating()
                }
            }else{
                let photoUrl = photo.imageUrl!
                let imageURL = NSURL(string: photoUrl)
                if let imageData = NSData(contentsOf: imageURL! as URL) {
                    photo.image = imageData
                    self.saveContext()
                    let image = UIImage(data: imageData as Data)
                    let imageView = UIImageView(image: image)
                    DispatchQueue.main.async {
                        cell.backgroundView = imageView
                        cell.activityIndicator.stopAnimating()
                    }
                } else {
                    print("Image does not exist at \(imageURL)")
                    DispatchQueue.main.async {
                        cell.activityIndicator.stopAnimating()
                    }
                }
                
            }
        }else{
            let imageView = UIImageView(image: nil)
            cell.backgroundView = imageView
            cell.activityIndicator.startAnimating()
        }
        
        if selectedPhotos == nil || selectedPhotos!.count == 0 {
            cell.contentView.backgroundColor = nil
            cell.isHighlighted = false
            cell.isSelected = false
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("NSFetchedResultsController - didChangeObject - Insert")
            photosCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            print("NSFetchedResultsController - didChangeObject - Delete")
            photosCollectionView.deleteItems(at: [indexPath!])
        case .update:
            print("NSFetchedResultsController - didChangeObject - Update")
            if let cell = photosCollectionView.cellForItem(at: indexPath!) as? PhotoCollectionViewCell{
                
            }
            let photo = controller.object(at: indexPath!) as! Photo
        case .move:
            print("NSFetchedResultsController - didChangeObject - Move")
            photosCollectionView.deleteItems(at: [indexPath!])
            photosCollectionView.insertItems(at: [newIndexPath!])
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controllerDidChangeContent called")
    }
}
