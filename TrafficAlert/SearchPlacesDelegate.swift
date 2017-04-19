//
//  SearchPlacesDelegate.swift
//  TrafficAlert
//
//  Created by Brandon Barooah on 4/13/17.
//  Copyright © 2017 TrafficAlert. All rights reserved.
//

import UIKit

class SearchPlacesTableSource: NSObject, UITableViewDelegate, UITableViewDataSource {

    var titlesList: [String]!
    var subtitlesList: [String]!
    
    weak var rowSelectedDelegate : TableRowSelectedDelegate?
    
    init(titles: [String], subtitles: [String]!){
        self.titlesList = titles
        self.subtitlesList = subtitles
    }
    
    convenience override init(){
        self.init(titles: [], subtitles: [])
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titlesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "tableCell")
        if(cell == nil){
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "tableCell")
        }
        cell?.textLabel?.text = titlesList[indexPath.row]
        cell?.detailTextLabel?.text = subtitlesList[indexPath.row]
        cell?.selectionStyle = UITableViewCellSelectionStyle.none
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        rowSelectedDelegate?.didSelectRow(title: (cell!.textLabel!.text!), subtitle: (cell?.detailTextLabel?.text))
    }
    
    
}
