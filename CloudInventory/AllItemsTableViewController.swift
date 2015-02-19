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
    
    override func viewWillAppear(animated: Bool) {
        
        //Reload data from core data
        reloadData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        
        var idStringRetrieved = ""
        var myPredicate = NSPredicate(format: "idString = %@", idStringRetrieved)
    }
    
    //Table View Data Source -
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.myInventory.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        
        if let oneItem = self.myInventory[indexPath.row] as? CoreDataModel {
            cell.textLabel?.text = oneItem.title
            cell.detailTextLabel?.text = oneItem.subtitle
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
    
    //Table View Refreshing
    @IBAction func tableViewRefreshTriggered(sender: AnyObject) {
        reloadData()
        tableView.reloadData()
        sender.endRefreshing()
    }
    
    func reloadData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let frequency = NSFetchRequest(entityName: "InventoryItem")
        
        myInventory = context.executeFetchRequest(frequency, error: nil)!
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addNew" {
            
        } else if segue.identifier == "update" {
            var selectedItem: CoreDataModel = myInventory[self.tableView.indexPathForSelectedRow()!.row] as CoreDataModel
            let myItemPageViewController: ItemPageViewController = segue.destinationViewController as ItemPageViewController
            myItemPageViewController.existingItem = selectedItem
        } else if segue.identifier == "toScanner" {
            
        }
    }
}
