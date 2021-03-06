//
//  SearchResultsViewController.swift
//  SwiftTest
//
//  Created by Daisuke Hirata on 6/17/14.
//  Copyright (c) 2014 Daisuke Hirata. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, APIControllerProtocol{
        
    @IBOutlet var appsTableView : UITableView
    
    var albums: Album[] = []
 
    // we need SearchResultsViewController to be instantiated before we pass self in as a delegate,
    // so we indicate api is a @lazy variable. It will only be created when it’s first used
    @lazy var api: APIController = APIController(delegate: self)
    
    var imageCache = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        api.searchItunesFor("Bob Dylan")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        let kCellIdentifier: String = "SearchResultCell"
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) as UITableViewCell
        
        // Find this cell's album by passing in the indexPath.row to the subscript method for an array of type Album[]
        let album = self.albums[indexPath.row]
        cell.text = album.title
        cell.image = UIImage(named: "Blank52")
        cell.detailTextLabel.text = album.price
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // Jump in to a background thread to get the image for this item
            
            // Grab the artworkUrl60 key to get an image URL for the app's thumbnail
            //var urlString: NSString = rowData["artworkUrl60"] as NSString
            let urlString = album.thumbnailImageURL
            
            // Check our image cache for the existing key. This is just a dictionary of UIImages
            var image = self.imageCache[urlString!] as? UIImage
            
            if( !image? ) {
                // If the image does not exist, we need to download it
                let imgURL = NSURL(string: urlString)
                
                // Download an NSData representation of the image at the URL
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                let urlConnection: NSURLConnection = NSURLConnection(request: request, delegate: self)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                    if !error? {
                        image = UIImage(data: data)
                        
                        // Store the image in to our cache
                        self.imageCache[urlString!] = image
                        
                        // Sometimes this request takes a while, and it's possible that a cell could be re-used before the art is done loading.
                        // Let's explicitly call the cellForRowAtIndexPath method of our tableView to make sure the cell is not nil, and therefore still showing onscreen.
                        // While this method sounds a lot like the method we're in right now, it isn't.
                        // Ctrl+Click on the method name to see how it's defined, including the following comment:
                        /** // returns nil if cell is not visible or index path is out of range **/
                        if let albumArtsCell: UITableViewCell? = tableView.cellForRowAtIndexPath(indexPath) {
                            albumArtsCell!.image = image
                        }
                    }
                    else {
                        println("Error: \(error.localizedDescription)")
                    }
                    })
                
            }
            else {
                cell.image = image
            }
            
            
            })
        return cell
    }

    /*
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // Get the row data for the selected row
        var album: Album = self.albums[indexPath.row]
        
        var alert: UIAlertView = UIAlertView()
        alert.title = album.title
        alert.message = album.price
        alert.addButtonWithTitle("Ok")
        alert.show()
    }
*/
    
    func didReceiveAPIResults(results: NSDictionary) {
        // Store the results in our table data array
        if results.count > 0 {
            
            let allResults: NSDictionary[] = results["results"] as NSDictionary[]
            
            // Sometimes iTunes returns a collection, not a track, so we check both for the 'name'
            for result: NSDictionary in allResults {
                
                var name: String? = result["trackName"] as? String
                if !name? {
                    name = result["collectionName"] as? String
                }
                
                // Sometimes price comes in as formattedPrice, sometimes as collectionPrice.. and sometimes it's a float instead of a string. Hooray!
                var price: String? = result["formattedPrice"] as? String
                if !price? {
                    price = result["collectionPrice"] as? String
                    if !price? {
                        var priceFloat: Float? = result["collectionPrice"] as? Float
                        var nf: NSNumberFormatter = NSNumberFormatter()
                        nf.maximumFractionDigits = 2;
                        if priceFloat? {
                            price = "$"+nf.stringFromNumber(priceFloat)
                        }
                    }
                }
                
                let thumbnailURL: String? = result["artworkUrl60"] as? String
                let imageURL: String? = result["artworkUrl100"] as? String
                let artistURL: String? = result["artistViewUrl"] as? String
                
                var itemURL: String? = result["collectionViewUrl"] as? String
                if !itemURL? {
                    itemURL = result["trackViewUrl"] as? String
                }
                
                var newAlbum = Album(name: name!, price: price!, thumbnailImageURL: thumbnailURL!, largeImageURL: imageURL!, itemURL: itemURL!, artistURL: artistURL!)
                
                albums.append(newAlbum)
            }
            
            
            dispatch_async(dispatch_get_main_queue(), {
                self.appsTableView.reloadData()
                })
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject) {
        let detailsViewController: DetailsViewController = segue.destinationViewController as DetailsViewController
        let albumIndex = appsTableView.indexPathForSelectedRow().row
        let selectedAlbum = self.albums[albumIndex]
        detailsViewController.album = selectedAlbum
    }
    
}

