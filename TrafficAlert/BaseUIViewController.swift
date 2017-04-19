//
//  BaseUIViewController.swift
//  TrafficAlert
//
//  Created by Brandon Barooah on 4/19/17.
//  Copyright © 2017 TrafficAlert. All rights reserved.
//

import UIKit

class BaseUIViewController: UIViewController {
    
    var loadingOverlay : UIView?
    var indicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayLoadingOverlay(viewToAddOn view:UIView? = nil, frameToLoadOn frame:CGRect? = nil){
        // if cgrect is not provided, default to screen size
        let viewToAddOn = view ?? self.view!
        let loadFrame = frame ?? viewToAddOn.frame
        
        // Initialize overlay view
        loadingOverlay = UIView(frame: loadFrame)
        loadingOverlay?.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
        
        // Add overlay to super view and bring to front
        viewToAddOn.addSubview(loadingOverlay!)
        viewToAddOn.bringSubview(toFront: loadingOverlay!)
        
        // Initialize indicator
        indicator = UIActivityIndicatorView(frame: loadFrame)
        indicator.activityIndicatorViewStyle = .gray
        indicator.startAnimating()
        viewToAddOn.addSubview(indicator)
        viewToAddOn.bringSubview(toFront: indicator)
        
    
    }
    
    func hideLoadingOverlay(){
        if (loadingOverlay != nil && indicator != nil){
            indicator.stopAnimating()
            indicator.removeFromSuperview()
            indicator = nil
            loadingOverlay?.removeFromSuperview()
            loadingOverlay = nil
        }
    }

}
