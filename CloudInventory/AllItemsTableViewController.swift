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
    
    private var myInventory = [AnyObject]()
    
    private struct Constants {
        static let TableViewCellID = "customItemTableViewCell"
    }
    
    private struct Segues {
        static let AddNewItem = AllSegues.AddNewItem
        static let UpdateItem = AllSegues.UpdateItem
        static let ScanCode = AllSegues.ScanItem
    }
    
    // MARK: - View Controller Lifecycle
    override func viewWillAppear(animated: Bool) {
        reloadData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        tableView.separatorColor = UIColor.blackColor()
        tableView.separatorInset = UIEdgeInsetsZero
    }
    
    // MARK: - Table View Configuration
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return myInventory.count }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: CustomItemTableViewCell = tableView.dequeueReusableCellWithIdentifier(Constants.TableViewCellID) as! CustomItemTableViewCell!
        
        let itemToDisplay: AnyObject = self.myInventory[indexPath.row]
        
        if itemToDisplay is ItemCoreDataModel {
            let item = itemToDisplay as! ItemCoreDataModel
            cell.cellTitle.text = itemToDisplay.title
            if item.photoOfItem != nil {
                cell.backgroundImage.image = UIImage(data: item.photoOfItem!)
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool { return true }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        
        if editingStyle == .Delete {
            context.deleteObject(myInventory[indexPath.row] as! NSManagedObject)
            
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
    
    // MARK: - Miscellaneous
    @IBAction private func tableViewRefreshTriggered(sender: AnyObject) {
        reloadData()
        tableView.reloadData()
        sender.endRefreshing()
    }
    
    private func reloadData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let itemFrequency = NSFetchRequest(entityName: CoreData.ItemEntity)
        
        var err: NSError?
        myInventory = context.executeFetchRequest(itemFrequency, error: &err)!
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Segues.AddNewItem:
                let myItemPageViewController: ItemPageViewController = segue.destinationViewController as! ItemPageViewController
                myItemPageViewController.hidesBottomBarWhenPushed = true
            case Segues.UpdateItem:
                let myItemPageViewController: ItemPageViewController = segue.destinationViewController as! ItemPageViewController
                myItemPageViewController.indexOfCurrentItemInMyInventoryArray = (self.tableView.indexPathForSelectedRow()!.row)
                myItemPageViewController.selectTitleAutomatically = false
                myItemPageViewController.hidesBottomBarWhenPushed = true
            case Segues.ScanCode:
                let myScannerViewController: ScannerViewController = segue.destinationViewController as! ScannerViewController
                myScannerViewController.hidesBottomBarWhenPushed = true
            default: break
            }
        }
    }
}
