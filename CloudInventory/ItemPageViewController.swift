import UIKit
import CoreData

//protocol ItemPageDataSource: class {
//    func folderNameForItemPage(sender: ItemPageViewController) -> String?
//}

class ItemPageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var textViewToolbar: UIToolbar!
    @IBOutlet weak var themeImageView: UIImageView!
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    
    //    weak var dataSource: ItemPageDataSource?
    var selectTitleAutomatically = true
    var qrCode: UIImage? {
        didSet {
            qrCodeImageView.image = qrCode
        }
    }
    var itemImage: UIImage? {
        didSet {
            pictureImageView.image = itemImage
            themeImageView.image = itemImage
            //primaryColor = UIColor(patternImage: itemImage!).colorWithAlphaComponent(0.5)
        }
    }
    var stringToEncode: String?
    lazy var utilitiesHelper = Helper()
    
    //All properties for updating an existing item's info
    var existingItem: ItemCoreDataModel?
    var itemTitle: String?
    var itemSubtitle: String?
    var itemNotes: String?
    var itemPhoto: NSData?
    var itemQrCodeNSData: NSData?
    var folderName: String? {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey("lastFolderNameSelected") as? String
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "lastFolderNameSelected")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    var indexOfCurrentItemInMyInventoryArray: Int? {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey("indexOfCurrentItemInMyInventoryArray") as? Int
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "indexOfCurrentItemInMyInventoryArray")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    //If the item is just being created
    var newItem: ItemCoreDataModel?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("CURRENT INDEX IS: \(indexOfCurrentItemInMyInventoryArray)")
        if indexOfCurrentItemInMyInventoryArray != nil {
            setAllPropertiesFromIndex(indexOfCurrentItemInMyInventoryArray!)
        } else if existingItem != nil {
            itemTitle = existingItem?.title
            itemSubtitle = existingItem?.subtitle
            itemNotes = existingItem?.notes
            itemPhoto = existingItem!.valueForKey("photoOfItem") as? NSData
            itemQrCodeNSData = existingItem!.valueForKey("qrCodeImage") as? NSData
            folderName = existingItem!.folder
        }
        if existingItem != nil {
            displayItemInfo()
            saveButton.title = "Done"
        }
        
        textViewToolbar.removeFromSuperview()
        titleTextField.delegate = self
        if selectTitleAutomatically == true {
            titleTextField.becomeFirstResponder()
        }
        subtitleTextField.delegate = self
        notesTextView.inputAccessoryView = textViewToolbar
    }
    
    func setAllPropertiesFromIndex(index: Int) {
        var myInventory = [AnyObject]()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let itemFrequency = NSFetchRequest(entityName: "InventoryItem")
        var err: NSError?
        myInventory = context.executeFetchRequest(itemFrequency, error: &err)!
        
        existingItem = myInventory[index] as? ItemCoreDataModel
        
        if existingItem != nil {
            println(existingItem?.title)
            itemTitle = existingItem?.title
            itemSubtitle = existingItem?.subtitle
            itemNotes = existingItem?.notes
            itemPhoto = existingItem?.valueForKey("photoOfItem") as? NSData
            itemQrCodeNSData = existingItem?.valueForKey("qrCodeImage") as? NSData
            folderName = existingItem?.folder
        }
    }
    
    @IBAction func saveTapped(sender: AnyObject) {
        saveAll()
        //clear chosen folder value
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "lastFolderNameSelected")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "indexOfCurrentItemInMyInventoryArray")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        //clear selected folder value
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "lastFolderNameSelected")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "indexOfCurrentItemInMyInventoryArray")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func actionButtonTapped(sender: UIBarButtonItem) {
        generateActionPopup(utilitiesHelper.convertQRCodeToData(qrCode!, jpeg: false), qrCodeImage: qrCode!, currentItemTitle: titleTextField.text)
    }
    
    @IBAction func trashTapped(sender: UIBarButtonItem) {
        var actionSheet = UIAlertController(title: "Trash", message: "Are you sure you want to delete this item?", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { action in
            let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let context: NSManagedObjectContext = appDelegate.managedObjectContext!
            
            if self.existingItem != nil {
                context.deleteObject(self.existingItem!)
            } else if self.newItem != nil {
                context.deleteObject(self.newItem!)
            }
            var error: NSError? = nil
            if !context.save(&error) {
                abort()
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        actionSheet.popoverPresentationController?.barButtonItem = trashButton
        actionSheet.popoverPresentationController?.sourceView = self.view
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func cameraTapped(sender: AnyObject) {
        createPhotoActionSheet()
    }
    
    @IBAction func doneTyping(sender: UIBarButtonItem) {
        notesTextView.resignFirstResponder()
    }
    //    @IBAction func folderTapped(sender: UIBarButtonItem) {
    //        var folderSelectionPopover = UIPopoverController(contentViewController: FolderSelectionTableViewController())
    //        folderSelectionPopover.presentPopoverFromBarButtonItem(organizeButton, permittedArrowDirections: .Up, animated: true)
    //    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func displayItemInfo() {
        if itemQrCodeNSData != nil {
            qrCode = UIImage(data: itemQrCodeNSData!)
        }
        if itemPhoto != nil {
            itemImage = UIImage(data: itemPhoto!)
        }
        titleTextField.text = itemTitle
        subtitleTextField.text = itemSubtitle
        notesTextView.text = itemNotes
    }
    
    func saveAll() {
        if titleTextField.text == nil || titleTextField.text == "" {
            var noTitleAlert = UIAlertController(title: "Title is required", message: "Please add a title to your item.", preferredStyle: .Alert)
            noTitleAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(noTitleAlert, animated: true, completion: nil)
            return
        }
        
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("InventoryItem", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "InventoryItem")
        
        var qrCodeImageToSave: NSData?
        
        
        if existingItem != nil { //updating existing item
            existingItem?.title = titleTextField.text
            existingItem?.subtitle = subtitleTextField.text
            existingItem?.notes = notesTextView.text
            if let pngOfPhoto = UIImagePNGRepresentation(pictureImageView.image) {
                existingItem?.photoOfItem = pngOfPhoto
            }
            existingItem?.dateLastEdited = NSDate()
            existingItem?.folder = folderName
        } else if existingItem == nil { //creating new item
            newItem = ItemCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
            newItem?.title = titleTextField.text
            newItem?.subtitle = subtitleTextField.text
            newItem?.notes = notesTextView.text
            newItem?.dateLastEdited = NSDate()
            newItem?.dateCreated = NSDate()
            newItem?.folder = folderName
            if let pngImage = UIImageJPEGRepresentation(itemImage, 1.0) {
                newItem?.photoOfItem = pngImage
            }
            
            //if qr code doesn't exist when save is tapped, generate a new one.
            if qrCode == nil {
                stringToEncode = utilitiesHelper.generateIdString(titleTextField.text, subtitle: subtitleTextField.text, notes: notesTextView.text)
                qrCode = utilitiesHelper.generateQRCodeForString(stringToEncode!)
                newItem?.idString = stringToEncode!
            }
            if qrCode != nil {
                var qrCodeNSData = utilitiesHelper.convertQRCodeToData(qrCode!, jpeg: true)
                newItem!.qrCodeImage = qrCodeNSData
            }
        }
        myContext.save(nil)
    }
    
    //Making Action Sheet
    func generateActionPopup(qrCodeToPrint: NSData, qrCodeImage: UIImage, currentItemTitle: String) {
        var actionSheet = UIAlertController(title: "Actions", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Print Code", style: UIAlertActionStyle.Default, handler: { action in
            var controller = self.utilitiesHelper.printFile(qrCodeToPrint, imageView: self.qrCodeImageView, jobTitle: self.titleTextField.text)
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                controller?.presentFromBarButtonItem(self.actionButton, animated: true, completionHandler: nil)
            } else {
                controller?.presentAnimated(true, completionHandler: nil)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Email Item", style: UIAlertActionStyle.Default, handler: { action in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        actionSheet.popoverPresentationController?.barButtonItem = actionButton
        actionSheet.popoverPresentationController?.sourceView = self.view
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    //CHOOSING/TAKING A PHOTO
    func createPhotoActionSheet() {
        if utilitiesHelper.determinePermissionStatus() == true {
            var camera = false
            var photoActionSheet = UIAlertController(title: "", message: "", preferredStyle: .ActionSheet)
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                camera = true
                photoActionSheet.addAction(UIAlertAction(title: "Take New", style: UIAlertActionStyle.Default, handler: { action in
                    self.takeNew()
                }))
            }
            
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
                camera = true
                photoActionSheet.addAction(UIAlertAction(title: "Choose from Photo Library", style: UIAlertActionStyle.Default, handler: { action in
                    self.selectFromLibrary()
                }))
            }
            
            if camera == false {
                noCameraAlert()
                return
            }
            photoActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {action in
                photoActionSheet.dismissViewControllerAnimated(true, completion: nil)
            }))
            photoActionSheet.popoverPresentationController?.barButtonItem = self.cameraButton
            photoActionSheet.popoverPresentationController?.sourceView = self.view
            
            self.presentViewController(photoActionSheet, animated: true, completion: nil)
        } else {
            noCameraPermissionAlert()
        }
    }
    
    
    func takeNew() {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let myAlertView = UIAlertView()
            myAlertView.title = "Error: Device has no camera or photo library."
            myAlertView.delegate = nil
            myAlertView.show()
        }
        var picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.Camera
        
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    func selectFromLibrary() {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let myAlertView = UIAlertView()
            myAlertView.title = "Error: Device has no photo library"
            myAlertView.delegate = nil
            myAlertView.show()
        }
        var picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    func noCameraAlert() {
        var noCameraAlert = UIAlertController(title: "Error", message: "Device has no camera", preferredStyle: .Alert)
        noCameraAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(noCameraAlert, animated: true, completion: nil)
    }
    
    func noCameraPermissionAlert() {
        var noCameraPermissionAlert = UIAlertController(title: "Permission Required", message: "We don't have permission to use your camera or photos.  Please revise your privacy settings. ", preferredStyle: .Alert)
        noCameraPermissionAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        noCameraPermissionAlert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { action in
            var appSettings: NSURL = NSURL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.sharedApplication().openURL(appSettings)
        }))
        self.presentViewController(noCameraPermissionAlert, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        itemImage = info["UIImagePickerControllerEditedImage"] as? UIImage
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //popover delegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "TextAlignment":
                if let vc = segue.destinationViewController as? TextAlignmentViewController {
                    if let ppc = vc.popoverPresentationController {
                        ppc.delegate = self
                    }
                }
            case "FolderSelection":
                if let vc = segue.destinationViewController as? FolderSelectionTableViewController {
                    if let ppc = vc.popoverPresentationController {
                        ppc.delegate = self
                    }
                    
                    //                    if let currentIndex = indexOfCurrentItemInMyInventoryArray {
                    //                        vc.folderSelectionIndexOfCurrentItemInMyInventoryArray = currentIndex
                    //                    }
                    
                    //                    vc.tempItemTitle = titleTextField.text
                    //                    vc.tempExistingItem = existingItem
                    //                    vc.tempNewItem = newItem
                    //                    vc.itemSubtitle = subtitleTextField.text
                    //                    vc.tempItemNotes = notesTextView.text
                    //                    vc.tempItemImage = itemImage
                    //                    vc.tempItemQRCodeNSData = itemQrCodeNSData
                    //                    vc.tempFolderName = folderName
                    
                }
                //preserve values to repopulate after folder is chosen
                //existingItem, newItem, itemTitle, itemSubtitle, itemNotes, itemPhoto, itemQRCodeNSData, folderName all need to be preserved
                
            default: break
            }
        }
    }
    
}

