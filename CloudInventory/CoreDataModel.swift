//
//  CoreDataModel.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 2/16/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import Foundation
import CoreData

class ItemCoreDataModel: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var subtitle: String?
    @NSManaged var notes: String?
    @NSManaged var photoOfItem: NSData?
    @NSManaged var qrCodeImage: NSData
    @NSManaged var idString: String
    @NSManaged var dateCreated: NSDate
    @NSManaged var dateLastEdited: NSDate
    @NSManaged var folder: String?
}

class FolderCoreDataModel: NSManagedObject {
    @NSManaged var name: String
}
