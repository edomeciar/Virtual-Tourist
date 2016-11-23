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
        let session = URLSession.shared
        let request = NSURLRequest()
    }
    
    func displayImageFromFlickrBySearch(methodParameters: [String:AnyObject],completitionHandler:@escaping (_ JSONResult: [[String: AnyObject?]]?, _ errorString: String?)->Void) {
        
        // create session and request
        let session = URLSession.shared
        let request = NSURLRequest(url: flickrURLFromParameters(parameters: methodParameters) as URL)
        
        // create network request
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                print("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            // pick a random page!
            let pageLimit = min(totalPages, 21)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            print("PageLimit \(pageLimit) randomPage \(randomPage)")
            self.displayImageFromFlickrBySearch(methodParameters: methodParameters, withPageNumber: randomPage, completitionHandler: completitionHandler)
        }
        
        // start the task!
        task.resume()
    }
    
    // FIX: For Swift 3, variable parameters are being depreciated. Instead, create a copy of the parameter inside the function.
    
    func displayImageFromFlickrBySearch(methodParameters: [String:AnyObject], withPageNumber: Int, completitionHandler:@escaping (_ JSONResult: [[String: AnyObject?]]?, _ errorString: String?)->Void) {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = NSURLRequest(url: flickrURLFromParameters(parameters: methodParametersWithPageNumber) as URL)
        
        // create network request
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                completitionHandler(nil,error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completitionHandler(nil,"There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completitionHandler(nil,"Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completitionHandler(nil,"No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            } catch {
                completitionHandler(nil,"Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completitionHandler(nil,"Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completitionHandler(nil,"Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completitionHandler(nil,"Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                completitionHandler(nil,"No Photos Found. Search Again.")
                return
            } else {
                
                completitionHandler(photosArray,nil)
                /*
                print("photo search count \(photosArray.count)")
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
                
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                    print("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                    return
                }
                
                // if an image exists at the url, set the image and title
                let imageURL = NSURL(string: imageUrlString)
                if let imageData = NSData(contentsOf: imageURL! as URL) {
                    print("image downloaded from imageUrl")
                } else {
                    print("Image does not exist at \(imageURL)")
                }
                */
            }
        }
        
        // start the task!
        task.resume()
    }

    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem as URLQueryItem)
        }
        print(components.url!)
        return components.url! as NSURL
    }
    
    public static func bboxString(latitude: Double,longitude : Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
    
    // MARK: TextField Validation
    
    public static func isCoordinateInRange(coordinate: Double, forRange: (Double, Double)) -> Bool {
        return isValueInRange(value: coordinate, min: forRange.0, max: forRange.1)
    }
    
    public static func isValueInRange(value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
