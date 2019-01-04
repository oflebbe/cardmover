//
//  TableDataSource.swift
//  explore3
//
//  Created by Olaf Flebbe on 03.01.19.
//  Copyright © 2019 Olaf Flebbe. All rights reserved.
//

import Foundation
import UIKit
import Contacts

class TableDataSource : NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let contactStore = CNContactStore();
    var contactContainers : [CNContainer] = []
    var groupsinContainers : [String:[CNGroup]] = [:]
    
    override init() {
        super.init()
        do {
            contactContainers = try contactStore.containers(matching: nil)
            for i in contactContainers {
                let groups = try contactStore.groups(matching:
                    CNGroup.predicateForGroupsInContainer(withIdentifier: i.identifier))
                groupsinContainers[ i.identifier] = groups
            }
        } catch {
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return contactContainers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = groupsinContainers[ contactContainers[section].identifier]?.count {
            return count+1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuse1", for: indexPath)
       
        if indexPath.row == 0 {
            cell.textLabel!.text = "All"
        } else {
            let group = groupsinContainers[ contactContainers[indexPath.section].identifier];
            if let group2 = group?[indexPath.row - 1] {
                cell.textLabel!.text = group2.name
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name = contactContainers[section].name
        switch contactContainers[section].type {
        case CNContainerType.local:
            return "Local: " + name
        case CNContainerType.cardDAV:
            return "CardDAV: " + name
        case CNContainerType.exchange:
            return "Exchange: " + name
        default:
            return "Unknown: " + name
        }
    }
   
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCell.AccessoryType.checkmark
        if indexPath.row == 0 {
            let groups = groupsinContainers[ contactContainers[indexPath.section].identifier]
            if let groups2 = groups {
                for g in 1...groups2.count {
                    tableView.cellForRow(at: IndexPath( row: g, section: indexPath.section))?.accessoryType = UITableViewCell.AccessoryType.checkmark
                }
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCell.AccessoryType.none
        if indexPath.row == 0 {
            let groups = groupsinContainers[ contactContainers[indexPath.section].identifier]
            if let groups2 = groups {
                for g in 1...groups2.count {
                    tableView.cellForRow(at: IndexPath( row: g, section: indexPath.section))?.accessoryType = UITableViewCell.AccessoryType.none
                }
            }
        }
    }
}

