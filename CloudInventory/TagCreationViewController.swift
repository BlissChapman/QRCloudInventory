//
//  TagCreationViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 3/12/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import CoreData

class TagCreationViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField!.delegate = self
            nameTextField.becomeFirstResponder()
        }
    }
    var newTag: TagCoreDataModel?
    var tags = [AnyObject]()
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSizeMake(nameTextField.frame.width, nameTextField.frame.height)
        checkData()
    }

    internal func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let tagName = nameTextField.text {
            if tags.count == 0 {
                createTag(tagName)
                return true
            }
            for index in 0...(tags.count - 1) {
                if tags[index].name == tagName {
                    var duplicateTagAlert = UIAlertController(title: "Duplicate Tag", message: "This tag already exists.", preferredStyle: .Alert)
                    duplicateTagAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    self.presentViewController(duplicateTagAlert, animated: true, completion: nil)
                    return true
                }
            }
            createTag(tagName)
            
        }
        return true
    }

    private func createTag(name: String) {
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName(CoreData.TagEntity, inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: CoreData.TagEntity)
        
        newTag = TagCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
        newTag?.name = nameTextField.text
        
        myContext.save(nil)
        //checkData()
        
        self.dismissViewControllerAnimated(true, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TagCreated, object: nil)
        println("posted notification")
    }
    
    private func checkData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let tagFrequency = NSFetchRequest(entityName: CoreData.TagEntity)
        
        var err: NSError?
        tags = context.executeFetchRequest(tagFrequency, error: &err)!
        if err != nil {
            println("Error = \(err?.description)")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
