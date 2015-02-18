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

class Helper {
    
    init() {}
    
    
    //QR CODES
    func generateQRCodeForString(stringToBeEncoded: String) -> UIImage {
        var stringData: NSData = stringToBeEncoded.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        var qrFilter: CIFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        var qrCode = UIImage(CIImage: qrFilter.outputImage)
        
        return qrCode!
    }
    
    func generateIdString(title: String, subtitle: String, notes: String) -> String {
        var randomIdentifier: Int = Int(arc4random())
        var randomIdentifier2: Int = Int(arc4random())
        return String(randomIdentifier) + title + subtitle + notes + String(randomIdentifier2)
    }
    
    func convertQRCodeToData(qrCodeImage: UIImage) -> NSData {
        UIGraphicsBeginImageContext(qrCodeImage.size)
        qrCodeImage.drawInRect(CGRectMake(0, 0, qrCodeImage.size.width, qrCodeImage.size.height))
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        var pngData = UIImagePNGRepresentation(newImage)
        return pngData
    }
    
    //PRINTING
    func printFile(data: NSData, image: UIImage, jobTitle: String) {
        if UIPrintInteractionController.canPrintData(data) {
            var controller: UIPrintInteractionController = UIPrintInteractionController.sharedPrintController()!
            controller.printingItem = image
            
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.outputType = UIPrintInfoOutputType.Grayscale
            printInfo.jobName = jobTitle
            controller.printInfo = printInfo
            
            let formatter = UIPrintFormatter()
            formatter.drawInRect(CGRectMake(100, 100, 50, 50), forPageAtIndex: 1)
            //formatter.contentInsets = UIEdgeInsets(top: 20, left: 20, bottom: 100, right: 100)
            controller.printFormatter = formatter
//            var printInfo = UIPrintInfo()
//            printInfo.outputType = UIPrintInfoOutputType.General
//            printInfo.jobName = jobTitle
            
//            var pageRenderer = UIPrintPageRenderer()
//            UIGraphicsGetCurrentContext()
//            var myPrintableRect = CGRectMake(100, 100, 100, 100)
//            pageRenderer.drawPageAtIndex(1, inRect: myPrintableRect)
//            UIGraphicsEndImageContext()
//            controller.printPageRenderer = pageRenderer
            
            controller.presentAnimated(true, completionHandler: nil)
        }
        
    }
    
    //DISPLAY ACTION SHEET WITH TITLES
    func generateActionPopup(qrCodeToPrint: NSData, qrCodeImage: UIImage, currentItemTitle: String) -> UIAlertController {
        var actionSheet = UIAlertController(title: "Actions", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Print", style: UIAlertActionStyle.Default, handler: { action in
            self.printFile(qrCodeToPrint, image: qrCodeImage, jobTitle: currentItemTitle)
        }))
        actionSheet.addAction(UIAlertAction(title: "Email Item", style: UIAlertActionStyle.Default, handler: { action in
            
        }))
        return actionSheet
    }
}