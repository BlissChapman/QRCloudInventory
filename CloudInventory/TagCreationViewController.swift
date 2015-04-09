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

    @IBOutlet weak var nameTextField: UITextField!
    
    var newTag: TagCoreDataModel?
    var tags = [AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        self.preferredContentSize = CGSizeMake(nameTextField.frame.width, nameTextField.frame.height)
        checkData()
        nameTextField.becomeFirstResponder()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
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

    func createTag(name: String) {
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("Tag", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "Tag")
        
        newTag = TagCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
        newTag?.name = nameTextField.text
        
        myContext.save(nil)
        //checkData()
        
        self.dismissViewControllerAnimated(true, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("Tag Created", object: nil)
        println("posted notification")
    }
    
    func checkData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let tagFrequency = NSFetchRequest(entityName: "Tag")
        
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
