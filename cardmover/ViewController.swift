//
//  ViewController.swift
//  explore3
//
//  Created by Olaf Flebbe on 03.01.19.
//  Copyright © 2019 Olaf Flebbe. All rights reserved.
//

import UIKit
import Contacts

class ViewController: UITableViewController {
    
    var tbvds : TableDataSource? = nil;
    
    @IBOutlet var tbv: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // self.tbv.isUserInteractionEnabled = true
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let authStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authStatus == CNAuthorizationStatus.notDetermined{
            let contactStore = CNContactStore.init()
            contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (success, nil) in
                
                if success {
                    self.tbvds = TableDataSource()
                    DispatchQueue.main.async {
                        self.tbv.dataSource = self.tbvds
                        self.tbv.delegate = self.tbvds
                        self.tbv.reloadData()
                    }
                    
                }
                else {
                    print("NOT")
                }
                
            })
        
        } else if authStatus == CNAuthorizationStatus.authorized{
            self.tbvds = TableDataSource()
            self.tbv.dataSource = self.tbvds
            self.tbv.delegate = self.tbvds
            self.tbv.reloadData()
        }
    }
    
    @IBAction func doAddressMove(_ sender: Any) {
        self.tbvds?.addressMove(self.tbv)
    }
}

