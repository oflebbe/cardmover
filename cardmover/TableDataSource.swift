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
    
    private func findGroupInDefaultContainer( _ name: String) -> CNGroup? {
        var newGroup : CNGroup? = nil
        for g in try! contactStore.groups(matching: CNGroup.predicateForGroupsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())) {
            if g.name == name {
                newGroup = g
                break
            }
        }
        return newGroup
    }
    
    public func createOrReturnGroupInDefaultContainer( _ name: String) -> CNGroup {
        if let ret = findGroupInDefaultContainer( name) {
            return ret
        } else {
            let saveRequest = CNSaveRequest()
            let newGroup = CNMutableGroup()
            newGroup.name = name
            saveRequest.add( newGroup, toContainerWithIdentifier: contactStore.defaultContainerIdentifier())
            try! contactStore.execute(saveRequest)
            if let ret = findGroupInDefaultContainer( name) {
                return ret
            } else {
                abort()
            }
        }
    }
    
    
    let allkeys = [
        CNContactNamePrefixKey,
        CNContactGivenNameKey,
        CNContactMiddleNameKey,
        CNContactFamilyNameKey,
        CNContactPreviousFamilyNameKey,
        CNContactNameSuffixKey,
        CNContactNicknameKey,
        CNContactOrganizationNameKey,
        CNContactDepartmentNameKey,
        CNContactJobTitleKey,
        CNContactPhoneticGivenNameKey,
        CNContactPhoneticMiddleNameKey,
        CNContactPhoneticFamilyNameKey,
        CNContactPhoneticOrganizationNameKey,
        CNContactBirthdayKey,
        CNContactNonGregorianBirthdayKey,
        CNContactNoteKey,
        CNContactImageDataKey,
        CNContactThumbnailImageDataKey,
        CNContactImageDataAvailableKey,
        CNContactTypeKey,
        CNContactPhoneNumbersKey,
        CNContactEmailAddressesKey,
        CNContactPostalAddressesKey,
        CNContactDatesKey,
        CNContactUrlAddressesKey,
        CNContactRelationsKey,
        CNContactSocialProfilesKey,
        CNContactInstantMessageAddressesKey]
    
    public func addressMove( _ tableView: UITableView) -> Int {
        // find defaultContainer
        var defaultContainer : CNContainer? = nil;
        for container in contactContainers {
            if container.identifier == contactStore.defaultContainerIdentifier() {
                defaultContainer = container
            }
        }
        if (defaultContainer == nil) {
            return 0
        }
        
        let request = CNContactFetchRequest(keysToFetch: allkeys as [CNKeyDescriptor])
        request.unifyResults = false
        request.mutableObjects = false
        request.predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())
        var defaultContacts = [CNContact]()
        
        do {
            try contactStore.enumerateContacts(with:request){
                (contact, cursor) -> Void in
                defaultContacts.append(contact)
            }
        } catch let error {
            NSLog("Fetch contact error: \(error)")
        }
        
        
        var moveContacts = [ CNContact]()
        var notAlreadyThereContacts = [ CNContact]()
        for container in contactContainers {
            if (container == defaultContainer) {
                continue;
            }
            
            for groupSelect in groupsinContainers[ container.identifier]! {
                if groupSelect.selected {
                    do {
                        let request = CNContactFetchRequest(keysToFetch: allkeys as [CNKeyDescriptor])
                        request.unifyResults = false
                        request.mutableObjects = false
                        request.predicate = CNContact.predicateForContactsInGroup(withIdentifier: groupSelect.identifier)
                        
                        do {
                            try contactStore.enumerateContacts(with:request){
                                (contact, cursor) -> Void in
                                moveContacts.append(contact)
                            }
                        } catch let error {
                            NSLog("Fetch contact error: \(error)")
                        }
                        
                        for c1 in moveContacts {
                            var found = false
                            for c2 in defaultContacts {
                               if c1.givenName == c2.givenName && c1.familyName == c2.familyName{
                                    found = true
                                    break
                                }
                            }
                            if !found {
                                notAlreadyThereContacts.append( c1)
                            }
                        }
                    }
                }
            }
            
            
        }
    
        let newGroup = createOrReturnGroupInDefaultContainer("New Group")
        let saveRequest = CNSaveRequest()
        var count = 0
        for c in notAlreadyThereContacts {
            let new = CNMutableContact()
            new.birthday = c.birthday
            new.contactType = c.contactType
            new.dates = c.dates
            new.familyName = c.familyName
            new.givenName = c.givenName
            new.departmentName = c.departmentName
            new.emailAddresses = c.emailAddresses
            new.jobTitle = c.jobTitle
            new.middleName = c.middleName
            new.namePrefix = c.namePrefix
            new.nameSuffix = c.nameSuffix
            new.nickname = c.nickname
            new.nonGregorianBirthday = c.nonGregorianBirthday
            new.note = c.note
            new.organizationName = c.organizationName
            new.phoneNumbers = c.phoneNumbers
            new.postalAddresses = c.postalAddresses
            new.previousFamilyName = c.previousFamilyName
            new.urlAddresses = c.urlAddresses
            
            saveRequest.add( new, toContainerWithIdentifier: nil)
            saveRequest.addMember( new, to: newGroup)
            count = count + 1
            
        }
        try! contactStore.execute(saveRequest)
        
        return count
    }
}

