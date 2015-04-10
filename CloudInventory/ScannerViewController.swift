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
    
    private var mySession = AVCaptureSession()
    private var preview = AVCaptureVideoPreviewLayer()
    private var encodedStringValue: String?
    private lazy var utilitiesHelper = Helper()
    private var selectedItem: ItemCoreDataModel?
    private var qrCodeFrameView = UIView()
    
    private struct Constants {
        static let ItemSharingQREncodedTag = "This item was created by Cloud Inventory."
    }
    
    private struct Segues {
        static let ItemPage = AllSegues.UpdateItemFromScanner
        static let TableView = AllSegues.BackToTableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            noCameraAlert()
        } else {
            configureScanner()
            qrCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
            mySession.startRunning()
        }
    }
    
    private func configureScanner() {
        let myInput = AVCaptureDeviceInput.deviceInputWithDevice(AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo), error: nil) as! AVCaptureDeviceInput
        
        var myOutput = AVCaptureMetadataOutput()
        mySession.addOutput(myOutput)
        mySession.addInput(myInput as AVCaptureInput)
        
        myOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        myOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        preview = AVCaptureVideoPreviewLayer.layerWithSession(mySession) as! AVCaptureVideoPreviewLayer
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        
        self.view.layer.insertSublayer(preview, atIndex: 0)
    }
    
    internal func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!,fromConnection connection: AVCaptureConnection!) {
        if metadataObjects != nil && metadataObjects.count > 0 {
            
            let metadataObjectFound: AnyObject = metadataObjects[0]
            if metadataObjectFound.type == AVMetadataObjectTypeQRCode {
                let barCodeObject = preview?.transformedMetadataObjectForMetadataObject(metadataObjectFound as! AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
                qrCodeFrameView.frame = barCodeObject.bounds
                encodedStringValue = metadataObjectFound.stringValue
                utilitiesHelper.playBeepSound()
                stopScanning()
            }
        } else {
            qrCodeFrameView.frame = CGRectZero
        }
    }
    
    private func stopScanning() {
        mySession.stopRunning()
        
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName(CoreData.ItemEntity, inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: CoreData.ItemEntity)
        
        var myPredicate = NSPredicate(format: "idString = %@", encodedStringValue!)
        println(myPredicate)
        frequency.predicate = myPredicate
        let myFetchRequestArray = myContext.executeFetchRequest(frequency, error: nil)!
        
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
                let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
                let myEntity = NSEntityDescription.entityForName(CoreData.ItemEntity, inManagedObjectContext: myContext)
                
                //println(ScanningConstants.ItemSharingQREncodedTag)
                let indexOfItemSharingTag: Int = count(Constants.ItemSharingQREncodedTag)
                let openingEncodedString = NSString.substringToIndex(Constants.ItemSharingQREncodedTag)
                
                println("opening encoded string = \(openingEncodedString(indexOfItemSharingTag))")
                
                var newItem = ItemCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
                newItem.title = self.encodedStringValue!
                newItem.subtitle = nil
                newItem.notes = nil
                newItem.photoOfItem = nil
                newItem.dateLastEdited = NSDate()
                newItem.dateCreated = NSDate()
                newItem.tags = nil
                
                
                //SHOULD CHECK IF ID STRING WITH THIS VALUE EXISTS - ns predicate
                newItem.idString = self.encodedStringValue!
                
                //recreates qr code from extracted string then converts to nsdata
                newItem.qrCodeImage = self.utilitiesHelper.convertQRCodeToData(self.utilitiesHelper.generateQRCodeForString("", subtitle: "", notes: "", fromString: self.encodedStringValue!).qrCode, jpeg: true)
                
                myContext.save(nil)
                self.performSegueWithIdentifier(Segues.TableView, sender: self)
                self.performSegueWithIdentifier(Segues.ItemPage, sender: self)
            }))
            presentViewController(createNewItem, animated: true, completion: nil)
        } else if myFetchRequestArray.count == 0 && encodedStringValue == nil {
            var fakeQRCode = UIAlertController(title: "QR code has no associated value.", message: "The code found does not have any readable information.", preferredStyle: UIAlertControllerStyle.Alert)
            fakeQRCode.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
                self.mySession.startRunning()
            }))
            presentViewController(fakeQRCode, animated: true, completion: nil)
        } else {
            selectedItem = myFetchRequestArray[0] as? ItemCoreDataModel
            performSegueWithIdentifier(Segues.TableView, sender: self)
            performSegueWithIdentifier(Segues.ItemPage, sender: self)
        }
    }
    
    private func noCameraAlert() {
        var noCameraAlert = UIAlertController(title: "Error", message: "Device has no camera", preferredStyle: .Alert)
        noCameraAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        presentViewController(noCameraAlert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Segues.ItemPage:
                let myItemViewController = segue.destinationViewController as! ItemPageViewController
                if selectedItem != nil {
                    myItemViewController.existingItem = selectedItem
                }
                myItemViewController.selectTitleAutomatically = false
                default: break
            }
        }
    }
}
