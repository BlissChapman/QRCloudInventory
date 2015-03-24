//
//  ScannerViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 2/16/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var mySession = AVCaptureSession()
    var preview = AVCaptureVideoPreviewLayer()
    var myDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var myOutput: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    var myInput: AVCaptureDeviceInput = AVCaptureDeviceInput()
    var encodedStringValue: String?
    
    lazy var utilitiesHelper = Helper()
    
    var selectedItem: ItemCoreDataModel?
    
    var myFetchRequestArray: [AnyObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            noCameraAlert()
        } else {
            setupScanner()
            mySession.startRunning()
        }
    }
    
    func setupScanner() {
        myInput = AVCaptureDeviceInput.deviceInputWithDevice(myDevice, error: nil) as AVCaptureDeviceInput
        
        mySession.addOutput(myOutput)
        mySession.addInput(myInput as AVCaptureInput)
        
        myOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        myOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        preview = AVCaptureVideoPreviewLayer.layerWithSession(mySession) as AVCaptureVideoPreviewLayer
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        
        self.view.layer.insertSublayer(preview, atIndex: 0)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!,fromConnection connection: AVCaptureConnection!) {
        if metadataObjects != nil && metadataObjects.count > 0 {
            var metadataObjectFound: AnyObject = metadataObjects[0]
            if metadataObjectFound.type == AVMetadataObjectTypeQRCode {
                encodedStringValue = metadataObjectFound.stringValue
                utilitiesHelper.playBeepSound()
                stopScanning()
            }
        }
    }
    
    func stopScanning() {
        mySession.stopRunning()
        performSegueWithIdentifier("toTableView", sender: self)
        
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("InventoryItem", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "InventoryItem")
        
        var myPredicate = NSPredicate(format: "idString = %@", encodedStringValue!)
        println(myPredicate)
        frequency.predicate = myPredicate
        myFetchRequestArray = myContext.executeFetchRequest(frequency, error: nil)!
        
        println("there are \(myFetchRequestArray.count) fetch request results")
        
        if myFetchRequestArray.count == 0 {
            var qrCodeExistsAlert = UIAlertController(title: "No item found for this QR code.", message: "Would you like to try again?", preferredStyle: UIAlertControllerStyle.Alert)
            
            qrCodeExistsAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
                self.navigationController?.popToRootViewControllerAnimated(true)
            }))
            qrCodeExistsAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
                self.mySession.startRunning()
            }))
        } else {
            selectedItem = myFetchRequestArray[0] as? ItemCoreDataModel
            println("itemTitle is = \(selectedItem?.title)")
            println("itemSubtitle = \(selectedItem?.subtitle)")
            println("itemInfo = \(selectedItem?.notes)")
            
            self.performSegueWithIdentifier("toItemPage", sender: self)
        }
    }
    
    func noCameraAlert() {
        var noCameraAlert = UIAlertController(title: "Error", message: "Device has no camera", preferredStyle: .Alert)
        noCameraAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(noCameraAlert, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toItemPage" {
            let myItemViewController = segue.destinationViewController as ItemPageViewController
            myItemViewController.existingItem = selectedItem
        }
    }
    
    
}
