//
//  MapViewDelegate.swift
//  TrafficAlert
//
//  Created by Brandon Barooah on 4/14/17.
//  Copyright © 2017 TrafficAlert. All rights reserved.
//

import UIKit
import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    var routeCount: Int = 0
    
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            if(mapView.overlays.count == routeCount){
                polylineRenderer.strokeColor = UIColor.blue.withAlphaComponent(0.75)
            } else {
                polylineRenderer.strokeColor = UIColor.gray.withAlphaComponent(0.75)
            }
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
    
}
