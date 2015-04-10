//
//  TagsTableViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 3/20/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import CoreData

class TagsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var myTags = [AnyObject]()
    
    private struct Segues {
        static let CreateTag = AllSegues.CreateTag
        static let FilteredTags = AllSegues.FilteredItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadInfo", name: "Tag Created", object: nil)
    }
    
    private func reloadInfo() {
        reloadData()
        self.tableView.reloadData()
    }
    
    private func reloadData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let itemFrequency = NSFetchRequest(entityName: CoreData.ItemEntity)
        let tagFrequency = NSFetchRequest(entityName: CoreData.TagEntity)
        
        var err: NSError?
        myTags = context.executeFetchRequest(tagFrequency, error: &err)!
    }

    // MARK: - Popover Delgate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // MARK: - Table View Configuration
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myTags.count
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        
        if editingStyle == .Delete {
            context.deleteObject(myTags[indexPath.row] as! NSManagedObject)
            
            myTags.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            var error: NSError? = nil
            if !context.save(&error) {
                abort()
            }
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tagCell", forIndexPath: indexPath) as! UITableViewCell
        
        if let itemToDisplay = self.myTags[indexPath.row] as? TagCoreDataModel {
            cell.textLabel?.text = itemToDisplay.name
        }
        

        // Configure the cell...

        return cell
    }


    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }


    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
            case Segues.CreateTag:
                if let vc = segue.destinationViewController as? TagCreationViewController {
                    if let ppc = vc.popoverPresentationController {
                        ppc.delegate = self
                    }
                }
            case Segues.FilteredTags:
                if let vc = segue.destinationViewController as? FilteredTaggedItemsTableViewController {
                    println(self.myTags[self.tableView.indexPathForSelectedRow()!.row].name)
                    let filteredResultsView: FilteredTaggedItemsTableViewController = segue.destinationViewController as! FilteredTaggedItemsTableViewController
                    
                    filteredResultsView.tagToSearch = self.myTags[self.tableView.indexPathForSelectedRow()!.row].name
                }
                
            default: break
            }
        }
        
    }


}
