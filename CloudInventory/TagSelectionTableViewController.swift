//
//  TagSelectionTableViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 3/26/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import CoreData

class TagSelectionTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    private struct Segues {
        static let CreateTag = AllSegues.CreateTag
    }
    
    var tags = [AnyObject]()
    var selectedTag = ""
    
    private var tagNames: String? {
        get { return NSUserDefaults.standardUserDefaults().valueForKey(Defaults.LastTagName) as? String }
        set { NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Defaults.LastTagName)
            NSUserDefaults.standardUserDefaults().synchronize() }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("made it to viewDidLoad")
        reloadInfo()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadInfo", name: Notifications.TagCreated, object: nil)
    }
    
    func reloadInfo() {
        reloadData()
        self.tableView.reloadData()
    }
    
    func reloadData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let tagFrequency = NSFetchRequest(entityName: CoreData.TagEntity)
        
        var err: NSError?
        tags = context.executeFetchRequest(tagFrequency, error: &err)!
        
        if err != nil {
            println("Error = \(err?.description)")
        }
        
        if tags.count > 0 {
            var item = tags[0].name
        }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        if let tag = self.tags[indexPath.row] as? TagCoreDataModel {
            cell.textLabel?.text = tag.name
            if tag.name == tagNames {
                cell.accessoryType = .Checkmark
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tagNames = tags[indexPath.row].name
        
        println("Name of the tag selected = \(tags[indexPath.row].name).  tagName now equals \(tagNames)")
        println(NSUserDefaults.standardUserDefaults().valueForKey(Defaults.LastTagName) as? String)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
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
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //popover delegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("about to segue with identifier \(segue.identifier)")
        if let identifier = segue.identifier {
            switch identifier {
            case Segues.CreateTag:
                if let vc = segue.destinationViewController as? TagCreationViewController {
                    if let ppc = vc.popoverPresentationController {
                        ppc.delegate = self
                    }
                }
                
            default: break
            }
        }
    }
    
}

