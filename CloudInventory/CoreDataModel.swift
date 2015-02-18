//
//  CoreDataModel.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 2/16/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import Foundation
import CoreData

//@objc(CoreDataModel)
class CoreDataModel: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var notes: String
    @NSManaged var photoOfItem: NSData
    @NSManaged var qrCodeImage: NSData
    @NSManaged var idString: String
}
