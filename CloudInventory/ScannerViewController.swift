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
    var newItem: ItemCoreDataModel?
    
    var myFetchRequestArray: [AnyObject] = []
    
    var qrCodeFrameView = UIView()
    var qrCodeImage: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            noCameraAlert()
        } else {
            setupScanner()
            qrCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
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
            
            let metadataObjectFound: AnyObject = metadataObjects[0]
            if metadataObjectFound.type == AVMetadataObjectTypeQRCode {
                let barCodeObject = preview?.transformedMetadataObjectForMetadataObject(metadataObjectFound as AVMetadataMachineReadableCodeObject) as AVMetadataMachineReadableCodeObject
                qrCodeFrameView.frame = barCodeObject.bounds
                encodedStringValue = metadataObjectFound.stringValue
                utilitiesHelper.playBeepSound()
                stopScanning()
            }
        } else {
            qrCodeFrameView.frame = CGRectZero
        }
    }
    
    func stopScanning() {
        mySession.stopRunning()
        
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("InventoryItem", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "InventoryItem")
        
        var myPredicate = NSPredicate(format: "idString = %@", encodedStringValue!)
        println(myPredicate)
        frequency.predicate = myPredicate
        myFetchRequestArray = myContext.executeFetchRequest(frequency, error: nil)!
        
        println("there are \(myFetchRequestArray.count) fetch request results")
        println("the encoded string has a value of '\(encodedStringValue);")
        if myFetchRequestArray.count == 0 && encodedStringValue != nil {
            var createNewItem = UIAlertController(title: "Not item in Inventory", message: "Would you like to create a new item for this code?", preferredStyle: UIAlertControllerStyle.Alert)
            
            createNewItem.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: { action in
                self.qrCodeFrameView.frame = CGRectZero
                self.mySession.startRunning()
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            createNewItem.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
                let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
                let myEntity = NSEntityDescription.entityForName("InventoryItem", inManagedObjectContext: myContext)
                self.newItem = ItemCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
                self.newItem?.title = self.encodedStringValue!
                self.newItem?.subtitle = nil
                self.newItem?.notes = nil
                self.newItem?.photoOfItem = nil
                self.newItem?.dateLastEdited = NSDate()
                self.newItem?.dateCreated = NSDate()
                self.newItem?.folder = nil
                
                
                //SHOULD CHECK IF ID STRING WITH THIS VALUE EXISTS - ns predicate
                self.newItem?.idString = self.encodedStringValue!
                
                //recreates qr code from extracted string then converts to nsdata - CHECK TO MAKE SURE IT WORKS
                self.newItem?.qrCodeImage = self.utilitiesHelper.convertQRCodeToData(self.utilitiesHelper.generateQRCodeForString(self.encodedStringValue!), jpeg: true)
    
                myContext.save(nil)
                self.performSegueWithIdentifier("toTableView", sender: self)
            }))
            self.presentViewController(createNewItem, animated: true, completion: nil)
        } else if myFetchRequestArray.count == 0 && encodedStringValue == nil {
            var fakeQRCode = UIAlertController(title: "QR code has no associated value.", message: "The code found does not have any readable information.", preferredStyle: UIAlertControllerStyle.Alert)
            fakeQRCode.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
                self.mySession.startRunning()
            }))
            self.presentViewController(fakeQRCode, animated: true, completion: nil)
        } else {
            selectedItem = myFetchRequestArray[0] as? ItemCoreDataModel
            self.performSegueWithIdentifier("toTableView", sender: self)
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
            if selectedItem != nil {
                myItemViewController.existingItem = selectedItem
            }
//            if newItem != nil {
//                println("newItem information")
//                myItemViewController.newItem = newItem
//                if encodedStringValue != nil {
//                    println("string value is not nil")
//                    myItemViewController.itemTitle = encodedStringValue
//                }
//                if qrCodeImage != nil {
//                    println("the image isnt nil...somehow")
//                    myItemViewController.qrCode = qrCodeImage
//                }
//            }
        }
    }
    
    
}
