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




struct GroupSelect {
    var name : String;
    var identifier : String;
    var selected : Bool;
    
    init( _ group : CNGroup ) {
        self.name = group.name;
        self.identifier = group.identifier
        self.selected = false;
    }
}

class TableDataSource : NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let contactStore = CNContactStore();
    var contactContainers : [CNContainer] = []
    var groupsinContainers : [String:[GroupSelect]] = [:]
    
    override init() {
        super.init()
        do {
            contactContainers = try contactStore.containers(matching: nil)
            for i in contactContainers {
                let groups = try contactStore.groups(matching:
                    CNGroup.predicateForGroupsInContainer(withIdentifier: i.identifier))
                groupsinContainers[ i.identifier] = []
                for group in groups {
                    groupsinContainers[ i.identifier]!.append(GroupSelect(group))
                }
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
            if let group = groupsinContainers[ contactContainers[indexPath.section].identifier] {
                cell.textLabel!.text = group[indexPath.row - 1].name
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name = contactContainers[section].name
        let defaultString = contactContainers[section].identifier == contactStore.defaultContainerIdentifier() ? " (default)" : ""
        
        switch contactContainers[section].type {
        case CNContainerType.local:
            return "Local: " + name + defaultString
        case CNContainerType.cardDAV:
            return "CardDAV: " + name + defaultString
        case CNContainerType.exchange:
            return "Exchange: " + name + defaultString
        default:
            return "Unknown: " + name + defaultString
        }
    }
    
    private func changeCheck( _ tableView: UITableView, didSelectRowAt indexPath: IndexPath, to value: Bool ) {
        let what = value ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        
        let containerIdentifier = contactContainers[indexPath.section].identifier
        if let groups = groupsinContainers[ containerIdentifier] {
            if indexPath.row == 0 {
                // All Checkmark
                tableView.cellForRow(at: indexPath)?.accessoryType = what
                for g in 1...groups.count {
                    // All others
                    tableView.cellForRow(at: IndexPath( row: g, section: indexPath.section))?.accessoryType = what
                    groupsinContainers[ containerIdentifier]![g-1].selected = value
                }
            } else {
                tableView.cellForRow(at: indexPath)?.accessoryType = what
                groupsinContainers[ containerIdentifier]![indexPath.row - 1].selected = value
            }
        } else {
            print("Internal Error1");
        }
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeCheck( tableView, didSelectRowAt: indexPath, to: true)
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        changeCheck( tableView, didSelectRowAt: indexPath, to: false)
    }
    
    public func addressMove( _ tableView: UITableView) {
        // find defaultContainer
        var defaultContainer : CNContainer? = nil;
        for container in contactContainers {
            if container.identifier == contactStore.defaultContainerIdentifier() {
                defaultContainer = container
            }
        }
        if (defaultContainer == nil) {
            return
        }
        var contacts : [ CNContact] = []
        for container in contactContainers {
            if (container == defaultContainer) {
                continue;
            }
            
            for groupSelect in groupsinContainers[ container.identifier]! {
                if groupSelect.selected {
                    do {
                        let contactsNew = try contactStore.unifiedContacts(matching: CNContact.predicateForContactsInGroup(withIdentifier: groupSelect.identifier), keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor])
                        contacts.append(contentsOf: contactsNew)
                    } catch {
                        
                    }
                }
            }
        }
        for c in contacts {
            c.
        }
        
    }
}

