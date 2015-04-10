//
//  FilteredTaggedItemsTableViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 3/23/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import CoreData

class FilteredTaggedItemsTableViewController: UITableViewController {
    
    var tagToSearch: String?
    lazy var helper = Helper()
    var filteredResults: [AnyObject]?
    
    //var testArray = ["HI", "table views are funky", "core data is for losers"]
    
    private struct Segues {
        static let UpdateItem = AllSegues.UpdateItemFromFiltered
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        tableView.separatorColor = UIColor.blackColor()
        tableView.separatorInset = UIEdgeInsetsZero
        
        if let tag = tagToSearch {
            filteredResults = helper.searchDatabaseForItemsWithTag(tag)!
            println("# of results = \(filteredResults?.count)")
        }
    }
    
    // MARK: - Table View Configuration
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println(filteredResults?.count)
        return filteredResults?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: CustomItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("customTaggedItemViewCell") as! CustomItemTableViewCell!
        
        //        var title: String = testArray[indexPath.row]
        //        println("title should be: \(title)")
        //        customCell.cellTitle.text = title
        //        customCell.backgroundImage.image = UIImage()
        
        if let itemToDisplay = self.filteredResults?[indexPath.row] as? ItemCoreDataModel {
            println("should be ok")
            cell.cellTitle.text = itemToDisplay.title
            if itemToDisplay.photoOfItem != nil {
                cell.backgroundImage.image = UIImage(data: itemToDisplay.photoOfItem!)
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        
        if editingStyle == .Delete {
            context.deleteObject(filteredResults![indexPath.row] as! NSManagedObject)
            
            filteredResults!.removeAtIndex(indexPath.row)
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
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Segues.UpdateItem :
                var selectedItem: ItemCoreDataModel = filteredResults![self.tableView.indexPathForSelectedRow()!.row] as! ItemCoreDataModel
                let myItemPageViewController: ItemPageViewController = segue.destinationViewController as! ItemPageViewController
                myItemPageViewController.existingItem = selectedItem
                myItemPageViewController.selectTitleAutomatically = false
                myItemPageViewController.hidesBottomBarWhenPushed = true
            default: break
            }
        }
    }
}
