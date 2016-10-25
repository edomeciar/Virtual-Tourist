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
    
    var mapPin: Pin!
    var mapLatitudeDelta: CLLocationDegrees!
    var mapLongituteDelta: CLLocationDegrees!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        detailMapView.addAnnotation(mapPin)
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        let region = MKCoordinateRegion(center: mapPin.coordinate, span: span)
        detailMapView.setRegion(region, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        return UICollectionViewCell()
    }
}
