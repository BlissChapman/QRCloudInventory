//
//  QRCodeHelper.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 2/17/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import AVFoundation
import CoreData

public struct Defaults {
    static let LastTagName = "lastTagNameSelected"
    static let IndexOfCurrentItem = "indexOfCurrentItemInMyInventoryArray"
}

public struct CoreData {
    static let ItemPhoto = "photoOfItem"
    static let QRCodeData = "qrCodeImage"
    static let ItemEntity = "InventoryItem"
    static let TagEntity = "Tag"
}

public struct Notifications {
    static let TagCreated = "Tag Created"
}

//Master list of all segue names for easier future maintenance - all prepareForSegues are based off structs that repackage these names to better describe the segue's purpose
public struct AllSegues {
    static let AddNewItem = "addNew"
    static let UpdateItem = "update"
    static let AlignText = "TextAlignment"
    static let SelectTag = "TagSelection"
    static let CreateTag = "TagCreation"
    static let ScanItem = "toScanner"
    static let BackToTableView = "toTableView"
    static let FilteredItems = "filteredTaggedItems"
    static let UpdateItemFromFiltered = "updateFromFiltered"
    static let UpdateItemFromScanner = "toItemPage"
}

class Helper {
    
    init() {}
    
    // MARK: - QR Codes
    func generateQRCodeForString(title: String, subtitle: String, notes: String, fromString: String?) -> (qrCode: UIImage, encodedString: String) {
        var stringToBeEncoded: String
        if fromString != nil {
            stringToBeEncoded = fromString!
        } else {
            stringToBeEncoded = generateIdString(title, subtitle: subtitle, notes: notes)
        }
        
        let stringData: NSData = stringToBeEncoded.dataUsingEncoding(NSISOLatin1StringEncoding, allowLossyConversion: true)!
        var qrFilter: CIFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter.setDefaults()
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
    
        let qrCode: UIImage? = self.createNonInterpolatedUIImageFromCIImage(qrFilter.outputImage, scale: 5.0)
        
        return (qrCode!, stringToBeEncoded)
    }
    
    private func createNonInterpolatedUIImageFromCIImage(image: CIImage, scale: CGFloat) -> UIImage {
        let cgImage: CGImageRef = CIContext(options: nil).createCGImage(image, fromRect: image.extent())
        UIGraphicsBeginImageContext(CGSizeMake(image.extent().size.width * scale, image.extent().size.height * scale))
        let context: CGContextRef = UIGraphicsGetCurrentContext()
        CGContextSetInterpolationQuality(context, kCGInterpolationNone)
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage)
        let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return UIImage(CGImage: scaledImage.CGImage, scale: scaledImage.scale, orientation: UIImageOrientation.DownMirrored)!
    }
    
    private func generateIdString(title: String, subtitle: String, notes: String) -> String {
        var randomIdentifier: Int = Int(arc4random())
        var randomIdentifier2: Int = Int(arc4random())
        return String(randomIdentifier) + title + subtitle + notes + String(randomIdentifier2)
    }
    
    func convertQRCodeToData(qrCodeImage: UIImage, jpeg: Bool) -> NSData {
        UIGraphicsBeginImageContext(qrCodeImage.size)
        qrCodeImage.drawInRect(CGRectMake(0, 0, qrCodeImage.size.width, qrCodeImage.size.height))
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if jpeg == true {
            var jpegData = UIImageJPEGRepresentation(newImage, 1.0)
            return jpegData
        }
        var pngData = UIImagePNGRepresentation(newImage)
        return pngData
    }
    
    //Camera permission status
    func determinePermissionStatus() -> (Bool){
        var authorized = false
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch status {
        case AVAuthorizationStatus.Authorized:
            return true
        case AVAuthorizationStatus.Denied:
            return false
        case AVAuthorizationStatus.Restricted:
            return false
        case AVAuthorizationStatus.NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted: Bool) in
                authorized = granted
            })
            return authorized
        }
    }
    
    
    //PRINTING
    func printFile(data: NSData, imageView: UIImageView, jobTitle: String) -> UIPrintInteractionController? {
        
        //create pdf from image
        var pdfData = NSMutableData(data: data)
        UIGraphicsBeginPDFContextToData(pdfData, CGRectZero, nil)
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(-20, 20, 500, 500), nil)
        
        imageView.layer.renderInContext(UIGraphicsGetCurrentContext())
        UIGraphicsEndPDFContext()
        
        var controller: UIPrintInteractionController?
        if UIPrintInteractionController.canPrintData(data) {
            controller = UIPrintInteractionController.sharedPrintController()!
            controller!.printingItem = pdfData
            
            let printInfo = UIPrintInfo(dictionary: nil)!
            printInfo.outputType = UIPrintInfoOutputType.General
            printInfo.jobName = jobTitle
            controller!.printInfo = printInfo
            
            return controller!
        } else {
            println("cannot print file at this time")
            controller = nil
        }
        return controller
    }
    
    //SCANNER
    func playBeepSound() {
        let url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("beep-07", ofType: "mp3")!)
        var error: NSError?
        if let beepSound = url {
            let audioPlayer = AVAudioPlayer(contentsOfURL: beepSound, error: &error)
            audioPlayer.volume = 1.0
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            if error != nil {
                println(error?.description)
            }
        }
    }
    
    //Search core data for items with certain tag 
    func searchDatabaseForItemsWithTag(tag: String) -> [AnyObject]? {
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("InventoryItem", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "InventoryItem")
        
        var myPredicate = NSPredicate(format: "tags = %@", tag)
        println(myPredicate)
        frequency.predicate = myPredicate
        
        var error = NSErrorPointer()
        myContext.executeFetchRequest(frequency, error: error)
        if error != nil {
            println(error.debugDescription)
        }
        return myContext.executeFetchRequest(frequency, error: nil) ?? nil
    }
}