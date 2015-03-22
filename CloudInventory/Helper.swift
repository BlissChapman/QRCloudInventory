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

class Helper {
    
    init() {}
    
    var audioPlayer = AVAudioPlayer()
    var iOSVersion: NSString = UIDevice.currentDevice().systemVersion
    
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
            audioPlayer = AVAudioPlayer(contentsOfURL: beepSound, error: &error)
            audioPlayer.volume = 1.0
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            if error != nil {
                println(error?.description)
            }
        }
    }
}