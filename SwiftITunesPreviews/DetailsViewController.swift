//
//  DetailsViewController.swift
//  SwiftTest
//
//  Created by Daisuke Hirata on 6/18/14.
//  Copyright (c) 2014 Daisuke Hirata. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {
    
    @IBOutlet var titleLabel : UILabel
    @IBOutlet var albumCover : UIImageView
    
    var album: Album?
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = self.album?.title
        albumCover.image = UIImage(data: NSData(contentsOfURL: NSURL(string: self.album?.largeImageURL)))        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
