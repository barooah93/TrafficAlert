//
//  ViewController.swift
//  TrafficAlert
//
//  Created by Brandon Barooah on 4/13/17.
//  Copyright © 2017 TrafficAlert. All rights reserved.
//

import UIKit
import MapKit.MKLocalSearch
import CoreLocation

protocol TableRowSelectedDelegate : class {
    func didSelectRow(title : String, subtitle : String?)
}

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
    func handleSearchRequest(response: MKLocalSearchResponse?)
    func plotPolyline(route: MKRoute)
}

class MainViewController: BaseUIViewController, MKLocalSearchCompleterDelegate, TableRowSelectedDelegate, UITextFieldDelegate{
    
    // Outlets
    @IBOutlet weak var mainUIScrollView: UIScrollView!

    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var fromUITextField: UITextField!
    @IBOutlet weak var toUITextField: UITextField!
    @IBOutlet weak var hourUITextField: UITextField!
    @IBOutlet weak var minUITextField: UITextField!
    @IBOutlet weak var phoneNumberUITextField: UITextField!
    @IBOutlet weak var setNotificationUIButton: UIButton!
    @IBOutlet weak var currentETAUILabel: UILabel!
    @IBOutlet weak var mapContainerUIView: UIView!
    
    // Properties
    var mapView: MKMapView!
    var mapDelegate: MapViewDelegate!
    var locationManager: CLLocationManager!
    
    var fromMapItem:MKMapItem? = nil
    var toMapItem:MKMapItem? = nil
    var fromAnnotation:MKPointAnnotation! = nil
    var toAnnotation:MKPointAnnotation! = nil
    
    var directionsETAInSeconds:Double! = nil
    
    var searchCompleter: MKLocalSearchCompleter!
    
    var fromSearchTableView: UITableView! = UITableView()
    var toSearchTableView: UITableView! = UITableView()
    
    var fromSearchTableSource: SearchPlacesTableSource!
    var toSearchTableSource: SearchPlacesTableSource!
    
    var isFromFieldFocused = false
    var isToFieldFocused = false
    
    var oldFromText: String = ""
    var oldToText: String = ""
    
    // Scroll view properties/gestures
    var panScrollViewGesture: UIPanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.searchCompleter = MKLocalSearchCompleter()
        self.searchCompleter.delegate = self
        self.searchCompleter.filterType = MKSearchCompletionFilterType.locationsOnly
        
        fromSearchTableSource = SearchPlacesTableSource()
        fromSearchTableSource.rowSelectedDelegate = self
        fromSearchTableView.dataSource = fromSearchTableSource
        fromSearchTableView.delegate = fromSearchTableSource
        self.mainUIScrollView.addSubview(fromSearchTableView)
        
        toSearchTableSource = SearchPlacesTableSource()
        toSearchTableSource.rowSelectedDelegate = self
        toSearchTableView.dataSource = toSearchTableSource
        toSearchTableView.delegate = toSearchTableSource
        self.mainUIScrollView.addSubview(toSearchTableView)
        
        // Textfield delegates
        fromUITextField.delegate = self
        toUITextField.delegate = self
        hourUITextField.delegate = self
        minUITextField.delegate = self
        phoneNumberUITextField.delegate = self
        
        // Tap gesture for content view
        let contentTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.scrollViewTapped(sender:)))
        scrollContentView.addGestureRecognizer(contentTapGesture)
        
        // UI adjustments
        currentETAUILabel.isHidden = true
        setNotificationUIButton.layer.cornerRadius = 5
        setNotificationUIButton.isEnabled = false
        setNotificationUIButton.alpha = 0.6
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Create table under from textfield
        fromSearchTableView.frame = CGRect(x: fromUITextField.frame.origin.x,
                                           y: fromUITextField.frame.origin.y + fromUITextField.frame.size.height,
                                           width: fromUITextField.frame.size.width,
                                           height: 150)
        fromSearchTableView.isHidden = true
        
        // Create table under to textfield
        toSearchTableView.frame = CGRect(x: toUITextField.frame.origin.x,
                                           y: toUITextField.frame.origin.y + toUITextField.frame.size.height,
                                           width: toUITextField.frame.size.width,
                                           height: 150)
        toSearchTableView.isHidden = true
        
        // Size the map only after views are layed out
        if(mapView == nil){
            var containerFrame = mapContainerUIView.frame
            containerFrame.origin.x += 5
            containerFrame.size.width -= 10
            mapView = MKMapView(frame: containerFrame)
            mapView.showsTraffic = true
            mapView.showsCompass = true
            mapView.mapType = .standard
            scrollContentView.addSubview(mapView)
            mapDelegate = MapViewDelegate()
            mapView.delegate = mapDelegate
        }

    }

    
    func scrollViewTapped(sender: UITapGestureRecognizer?) {
        // Enable scrollview scrolling
        self.mainUIScrollView.isScrollEnabled = true
        
        // Hide tables
        fromSearchTableView?.isHidden = true
        toSearchTableView?.isHidden = true
        
        // Hide keyboard and remove focus
        self.scrollContentView.subviews.forEach{ view in
            if(view is UITextField){
                view.resignFirstResponder()
            }
        }
        
        // Remove gestures
        if(panScrollViewGesture != nil){
            scrollContentView.removeGestureRecognizer(panScrollViewGesture!)
            panScrollViewGesture = nil
        }
    }
    
    // Method called while typing (use to restrict unwanted characters in textfield)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if(string.isEmpty){
            return true
        }
        
        if(textField == hourUITextField || textField == minUITextField || textField == phoneNumberUITextField){
            // Ensure only numbers are entered
            if(Int(string) == nil){
                return false
            }
        }
        return true
    }
    
    // Method to handle when textfields are out of focus
    func textFieldDidEndEditing(_ textField: UITextField) {
        if(textField == fromUITextField){
            fromUITextField.text = oldFromText
        } else if(textField == toUITextField){
            toUITextField.text = oldToText
        }
        self.scrollViewTapped(sender: nil)
    }

    // Method to handle text field text changes on screen
    @IBAction func editingChanged(_ sender: AnyObject) {
        
        if let textField = sender as? UITextField{
            
            // If text is empty, clear tables
            if(textField.text!.isEmpty){
                if(isFromFieldFocused){
                    fromSearchTableSource.titlesList = []
                    fromSearchTableView.reloadData()
                }
                if(isToFieldFocused){
                    toSearchTableSource.titlesList = []
                    toSearchTableView.reloadData()
                }
            }
            else if(textField == fromUITextField || textField == toUITextField){
                // Perform completer query
                searchCompleter.queryFragment = textField.text!
            }
            
        }
        
        // Also check if all textfields have text, in which case activate the notifcation button
        var activateNotificationButton = true
        if(fromUITextField.text!.isEmpty
            || toUITextField.text!.isEmpty
            || (hourUITextField.text!.isEmpty && minUITextField.text!.isEmpty)
            || phoneNumberUITextField.text!.isEmpty){
            activateNotificationButton = false
        }
        self.setNotificationUIButton.isEnabled = activateNotificationButton
        self.setNotificationUIButton.alpha = activateNotificationButton ? 1.0 : 0.6
        
        
    }
    
    // Method to handle showing the table for search results when text field is selected
    @IBAction func editingDidBegin(_ sender: AnyObject) {
        if let textField = sender as? UITextField{
            if(textField == fromUITextField){
                isFromFieldFocused = true
                isToFieldFocused = false
                fromSearchTableView.isHidden = false
                toSearchTableView.isHidden = true
            } else if(textField == toUITextField){
                isToFieldFocused = true
                isFromFieldFocused = false
                toSearchTableView.isHidden = false
                fromSearchTableView.isHidden = true
            }
            
            // Disable scroll view scrolling and allow table view scrolling
            self.mainUIScrollView.isScrollEnabled = false
            
            // Add pan gesture to allow user to pan while focused on from or to textfield
            panScrollViewGesture = UIPanGestureRecognizer(target: self, action: #selector(self.scrollViewTapped))
            panScrollViewGesture?.cancelsTouchesInView = false
            self.scrollContentView.addGestureRecognizer(panScrollViewGesture!)
        
        }
    }
    
    // Event that gets called when data is returned
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        
        var titles = [String]()
        var subtitles = [String]()
        completer.results.forEach{ result in
            titles.append(result.title)
            subtitles.append(result.subtitle)
        }
        
        // Update from search table
        if(isFromFieldFocused){
            fromSearchTableSource.titlesList = titles
            fromSearchTableSource.subtitlesList = subtitles
            fromSearchTableView.reloadData()
        } else if(isToFieldFocused){ // Update to search table
            toSearchTableSource.titlesList = titles
            toSearchTableSource.subtitlesList = subtitles
            toSearchTableView.reloadData()
        }
    }
    
    // Delegate called when row from a table was selected
    func didSelectRow(title : String, subtitle:String? = nil){
        let searchString = title + " " + (subtitle ?? "")
        
        if(isFromFieldFocused){
            fromUITextField.text = searchString
            oldFromText = searchString
        } else if(isToFieldFocused){
            toUITextField.text = searchString
            oldToText = searchString
        }
        
        self.scrollViewTapped(sender: nil)
        
        // Make a request to mklocalsearch to display pin/directions on map
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchString
        let search = MKLocalSearch(request: request)
        
        // Show spinner
        self.displayLoadingOverlay(viewToAddOn: scrollContentView, frameToLoadOn: mapContainerUIView.frame)
        search.start { response, _ in
           self.handleSearchRequest(response: response)
     
        }
        
    }
    
    
    // Method to handle set notification button click
    @IBAction func SetNotifcationButton_TouchUpInside(_ sender: Any) {
        // Error check parameters before calling api
        if(fromMapItem == nil || toMapItem == nil){
            let emptyAddressAlert = UIAlertController(title: "Alert!", message: "Please select a valid 'From' and 'To' location.", preferredStyle: .alert)
            emptyAddressAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyAddressAlert, animated: true)
            return
        }
        
        var seconds : Double = 0
        // Convert threshold time to seconds
        if let hours = Double(hourUITextField.text!) {
            seconds += hours * 3600
        }
        if let minutes = Double(minUITextField.text!){
            seconds += minutes * 60
        }
        
        // Check if eta is already below threshold
        if(seconds > directionsETAInSeconds!){
            let minTimeAlert = UIAlertController(title: "FYI", message: "The estimated time to your destination is already below your threshold, are you sure you want to continue?", preferredStyle: .alert)
            minTimeAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(alert: UIAlertAction!) in
                self.ContinueToCallApi(seconds: seconds)
            }))
                
            minTimeAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(minTimeAlert, animated: true)
        } else {
            
            self.ContinueToCallApi(seconds: seconds)
        }
        
        
    }
    
    func ContinueToCallApi(seconds: Double!){
        // Create request object and call api method
        let trafficRequest = TrafficAlertRequest()
        trafficRequest.fromCoordinate = Coordinate("", "")
        self.CallApi(trafficRequest: trafficRequest)
    }
    
    func CallApi(trafficRequest: TrafficAlertRequest){
        // Process request
        var request = URLRequest(url: URL(string:"https://jsonplaceholder.typicode.com/posts/1")!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        session.dataTask(with: request){data, response, err in
            let jsonData = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let response = jsonData as? [String:Any]{
                print(response)
            }
        }.resume()
    }


}

extension MainViewController: HandleMapSearch {
    func handleSearchRequest(response: MKLocalSearchResponse?){
        if let mapItems = response?.mapItems{
            if(self.isFromFieldFocused){
                self.fromMapItem = mapItems[0]
            } else if(self.isToFieldFocused){
                self.toMapItem = mapItems[0]
            }
            self.dropPinZoomIn(placemark: mapItems[0].placemark)
        }
        
    }
    
    func dropPinZoomIn(placemark:MKPlacemark){
        // clear existing pins
        if(self.isFromFieldFocused){
            if(fromAnnotation != nil){
                mapView.removeAnnotation(fromAnnotation)
                mapView.removeOverlays(mapView.overlays)
            }
            fromAnnotation = MKPointAnnotation()
            fromAnnotation.coordinate = placemark.coordinate
            fromAnnotation.title = placemark.name
            if let city = placemark.locality,
                let state = placemark.administrativeArea {
                fromAnnotation.subtitle = "\(city) \(state)"
            }
            mapView.addAnnotation(fromAnnotation)
        } else if(self.isToFieldFocused){
            if(toAnnotation != nil){
                mapView.removeAnnotation(toAnnotation)
                mapView.removeOverlays(mapView.overlays)
            }
            toAnnotation = MKPointAnnotation()
            toAnnotation.coordinate = placemark.coordinate
            toAnnotation.title = placemark.name
            if let city = placemark.locality,
                let state = placemark.administrativeArea {
                toAnnotation.subtitle = "\(city) \(state)"
            }
            mapView.addAnnotation(toAnnotation)
        }
        
        if(fromMapItem != nil && toMapItem != nil){
            // Show directions
            // 1
            let request: MKDirectionsRequest = MKDirectionsRequest()
            request.source = fromMapItem
            request.destination = toMapItem
            // 2
            request.requestsAlternateRoutes = true
            // 3
            request.transportType = .automobile
            // 4
            // mkdirections request
            let directions = MKDirections(request: request)
            directions.calculate(completionHandler: ({
                (response, error) in
                if error != nil {
                    let alert = UIAlertController(title: "Alert!", message: "We were unable to plot the directions on the map", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else if(response != nil){
                    // Sort routes ascending order and draw them, this way the lastly drawn route will be on top
                    let sortedRoutes =
                        response!.routes.sorted(by: {$0.expectedTravelTime >
                            $1.expectedTravelTime})
                    self.mapDelegate.routeCount = sortedRoutes.count
                    sortedRoutes.forEach{route in
                        self.plotPolyline(route: route)
                    }
                    self.directionsETAInSeconds = sortedRoutes.last!.expectedTravelTime
                    let hours = Int(sortedRoutes.last!.expectedTravelTime / 3600)
                    let minutes = Int(sortedRoutes.last!.expectedTravelTime.truncatingRemainder(dividingBy: 3600)  / 60)
                    var timeString = "Current ETA:"
                    if(hours != 0){
                        timeString += " \(hours)hr"
                    }
                    timeString += " \(minutes)min"
                    self.currentETAUILabel.text = timeString
                    self.currentETAUILabel.isHidden = false
                }
                self.hideLoadingOverlay()
            }))
            
        } else {
            // Show pin
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegionMake(placemark.coordinate, span)
            mapView.setRegion(region, animated: true)
            self.hideLoadingOverlay()
        }
    }
    
    func plotPolyline(route: MKRoute) {
        // 1
        mapView.add(route.polyline, level: .aboveRoads)
        // 2
        mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                      edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0),
                                      animated: true)
    }
}

