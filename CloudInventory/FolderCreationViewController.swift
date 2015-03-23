//
//  FolderCreationViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 3/12/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import CoreData

class FolderCreationViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    
    var newFolder: FolderCoreDataModel?
    var folders = [AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        self.preferredContentSize = CGSizeMake(nameTextField.frame.width, nameTextField.frame.height)

    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let folderName = nameTextField.text {
            createFolder(folderName)
        }
        return true
    }

    func createFolder(name: String) {
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("Folder", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "Folder")
        
        newFolder = FolderCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
        newFolder?.name = nameTextField.text
        
        myContext.save(nil)
        checkData()
        
        self.dismissViewControllerAnimated(true, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("Folder Created", object: nil)
    }
    
    func checkData() {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let folderFrequency = NSFetchRequest(entityName: "Folder")
        
        var err: NSError?
        folders = context.executeFetchRequest(folderFrequency, error: &err)!
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
