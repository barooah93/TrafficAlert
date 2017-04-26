//
//  TrafficAlertRequest.swift
//  TrafficAlert
//
//  Created by Brandon Barooah on 4/26/17.
//  Copyright © 2017 TrafficAlert. All rights reserved.
//

import UIKit

class TrafficAlertRequest: NSObject {
    
    var fromCoordinate: Coordinate!
    
    var toCoordinate:Coordinate!
    
    var fromAddress:String!
    var toAddress:String!
    var minimumSeconds:String!
    var phoneNumber:String!

}

class Coordinate: NSObject{
    
    var latitude:String!
    var longitude:String!
    
    init(_ lat:String!, _ long:String!) {
        self.latitude = lat
        self.longitude = long
    }
   
}
