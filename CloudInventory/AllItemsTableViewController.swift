//
//  AllItemsTableViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 2/16/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import CoreData

class AllItemsTableViewController: UITableViewController {
    
    var myInventory = [AnyObject]()
    //var itemsWithNoFolders = [AnyObject]()
    //var myFolders = [AnyObject]()
    //var arrayToDisplay = [AnyObject]()
    
    override func viewWillAppear(animated: Bool) {
        reloadData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        tableView.separatorColor = UIColor.blackColor()
        tableView.separatorInset = UIEdgeInsetsZero
        
        var idStringRetrieved = ""
        var myPredicate = NSPredicate(format: "idString = %@", idStringRetrieved)
    }
    
    //Table View Data Source -
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //println("there should be \(self.itemsWithNoFolders.count + self.myFolders.count) items")
        //return self.itemsWithNoFolders.count + self.myFolders.count
        println("new row")
        return myInventory.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: CustomItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("customItemTableViewCell") as CustomItemTableViewCell!
        
        let itemToDisplay: AnyObject = self.myInventory[indexPath.row]
        //        if itemToDisplay is FolderCoreDataModel {
        //            //println("ITS A FOLDER :D")
        //            cell.textLabel?.text = itemToDisplay.name
        //            cell.imageView?.image = UIImage(named: "TagIcon.png")
        // } else
        if itemToDisplay is ItemCoreDataModel {
            //println("NOT A FOLDER :D")
            //println("@indexPath \(indexPath.row)")
            let item = itemToDisplay as ItemCoreDataModel
            cell.cellTitle.text = itemToDisplay.title
            cell.backgroundImage.image = UIImage(data: item.photoOfItem)
//            cell.textLabel?.text = itemToDisplay.title
//            cell.detailTextLabel?.text = item.subtitle
//            cell.imageView?.image = UIImage(data: item.photoOfItem)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        
        if editingStyle == .Delete {
            context.deleteObject(myInventory[indexPath.row] as NSManagedObject)
            
            myInventory.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            var error: NSError? = nil
            if !context.save(&error) {
                abort()
            }
        }
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return UIScreen.mainScreen().bounds.size.height / 7.0
        }
        return UIScreen.mainScreen().bounds.size.height / 9.4
    }
    
    //Table View Refreshing
    @IBAction func tableViewRefreshTriggered(sender: AnyObject) {
        reloadData()
        tableView.reloadData()
        sender.endRefreshing()
    }
    
    func reloadData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let itemFrequency = NSFetchRequest(entityName: "InventoryItem")
        let folderFrequency = NSFetchRequest(entityName: "Folder")
        
        var err: NSError?
        myInventory = context.executeFetchRequest(itemFrequency, error: &err)!
//        myFolders = context.executeFetchRequest(folderFrequency, error: &err)!
//        itemsWithNoFolders = []
        
//        println("there are \(myInventory.count) items to put in either a folder or to leave as a regular item...there are \(myFolders.count) folders")
//        for index in 0 ..< myInventory.count {
//            println(index)
//            if myInventory[index] is FolderCoreDataModel {
//            } else {
//                itemsWithNoFolders.append(myInventory[index])
//            }
//        }
//        arrayToDisplay = myFolders + itemsWithNoFolders
//        println("there are \(arrayToDisplay.count) items to display")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addNew" {
            println("addNew was segue")
            let myItemPageViewController: ItemPageViewController = segue.destinationViewController as ItemPageViewController
            myItemPageViewController.hidesBottomBarWhenPushed = true
        } else if segue.identifier == "update" {
            println(self.tableView.indexPathForSelectedRow()!.row)
            //var selectedItem: ItemCoreDataModel = myInventory[self.tableView.indexPathForSelectedRow()!.row] as! ItemCoreDataModel// - myFolders.count] as! ItemCoreDataModel
            let myItemPageViewController: ItemPageViewController = segue.destinationViewController as ItemPageViewController
            myItemPageViewController.indexOfCurrentItemInMyInventoryArray = (self.tableView.indexPathForSelectedRow()!.row)// - myFolders.count)
            //myItemPageViewController.existingItem = selectedItem
            myItemPageViewController.hidesBottomBarWhenPushed = true
        } else if segue.identifier == "toScanner" {
            let myScannerViewController: ScannerViewController = segue.destinationViewController as ScannerViewController
            myScannerViewController.hidesBottomBarWhenPushed = true
        }
    }
}
