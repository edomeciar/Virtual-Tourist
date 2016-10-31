//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Eduard Meciar on 31/10/2016.
//  Copyright © 2016 Eduard Meciar. All rights reserved.
//

import Foundation

class FlickrClient : NSObject{
    
    let SecureUrl = "https://api.flickr.com/services/rest/"
    let ApiKey = "d2cbf57d0a827317a6f35cdbfc6c8e89"
    let MethodName = "flickr.photos.search"
    

    
    func searchPhotosByLatLon(pin: Pin){
        let session = URLSession.sharedSession()
        let request = NSURLRequest()
    }
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
}
