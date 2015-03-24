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
    
    var testArray = ["HI", "table views are funky", "core data is for losers"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        
//        if let tag = tagToSearch {
//            filteredResults = helper.searchDatabaseForItemsWithTag(tag)!
//            println("# of results = \(filteredResults?.count)")
//            println(filteredResults)
//            //println("the first item's title is \((self.filteredResults![0] as? ItemCoreDataModel).title)")
//        }
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println(filteredResults?.count)
        return testArray.count// ?? 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var customCell: CustomItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("customTaggedItemViewCell") as CustomItemTableViewCell!
        
        var title: String = testArray[indexPath.row]
        println("title should be: \(title)")
        customCell.cellTitle.text = title
        customCell.backgroundImage.image = UIImage()
//        let itemToDisplay: AnyObject = self.filteredResults![indexPath.row]
//        println("itemToDisplay = \(itemToDisplay)")
//        
//        println(filteredResults![indexPath.row] as? ItemCoreDataModel)
//        if let itemToDisplay = self.filteredResults?[indexPath.row] as? ItemCoreDataModel {
//            println("should be ok")
//            //cell.cellTitle.text = itemToDisplay.title
//            //cell.backgroundImage.image = UIImage(data: item.photoOfItem)
//        }
        println("returning a cell")
        return customCell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        
        if editingStyle == .Delete {
            context.deleteObject(filteredResults![indexPath.row] as NSManagedObject)
            
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
