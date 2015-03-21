import UIKit
import CoreData

protocol ItemPageDataSource: class {
    //NOTE: ALSO NEED TO PRESERVE INDEX OF SELECTED ITEM IN ARRAY so i can delete it if necessary
    //qr code, itemImage, primaryColor, complementaryColor, existingItem, itemTitle, itemSubtitle, itemNotes, itemPhoto (nsdata), itemQRCodeNSData, folderName, newItem
    //    func qrCodeForItemPage(sender: ItemPageViewController) -> UIImage?
    //    func itemImageForItemPage(sender: ItemPageViewController) -> UIImage?
    //    func primaryColorForItemPage(sender: ItemPageViewController) -> UIColor?
    //    func complementaryColorForItemPage(sender: ItemPageViewController) -> UIColor?
    //    func existingItemForItemPage(sender: ItemPageViewController) -> ItemCoreDataModel?
    //    func itemTitleForItemPage(sender: ItemPageViewController) -> String?
    //    func itemSubtitleForItemPage(sender: ItemPageViewController) -> String?
    //    func itemNotesForItemPage(sender: ItemPageViewController) -> String?
    //    func itemPhotoForItemPage(sender: ItemPageViewController) -> NSData?
    //    func itemQRCodeNSDataForItemPage(sender: ItemPageViewController) -> NSData?
    func folderNameForItemPage(sender: ItemPageViewController) -> String?
    //    func newItemForItemPage(sender: ItemPageViewController) -> ItemCoreDataModel?
}

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
    
    
    weak var dataSource: ItemPageDataSource?
    var qrCode: UIImage? {
        didSet {
            qrCodeImageView.image = qrCode
        }
    }
    var itemImage: UIImage? {
        didSet {
            pictureImageView.image = itemImage
            themeImageView.image = itemImage
            primaryColor = UIColor(patternImage: itemImage!).colorWithAlphaComponent(0.5)
        }
    }
    var primaryColor: UIColor? {
        didSet{
            notesTextView.backgroundColor = primaryColor
            //            var primaryHue = UnsafeMutablePointer<CGFloat>()
            //            var primarySaturation = UnsafeMutablePointer<CGFloat>()
            //            var primaryBrightness = UnsafeMutablePointer<CGFloat>()
            //            var primaryAlpha = UnsafeMutablePointer<CGFloat>()
            //            println(primaryColor)
            //            if primaryColor?.getHue(primaryHue, saturation: primarySaturation, brightness: primaryBrightness, alpha: primaryAlpha) == true {
            //                println(primaryHue)
            //                println(primarySaturation)
            //                println(primaryAlpha)
            //                complementaryColor =
        }
    }
    
    var complementaryColor: UIColor? {
        didSet{
            UIButton.appearance().tintColor = complementaryColor
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
    var folderName: String?//
    var indexOfCurrentItemInMyInventoryArray: Int?
    
    //All properties for creating a new item
    var newItem: ItemCoreDataModel?
    
    
    override func viewWillAppear(animated: Bool) {
        println("viewWillAppear is called here...")
        
    }
    
    override func viewDidLoad() {
        println("viewDidLoad is called here...")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //existingItem is set based on the table view row selected
        if existingItem != nil {
            itemTitle = existingItem!.title
            itemSubtitle = existingItem!.subtitle
            itemNotes = existingItem!.notes
            itemPhoto = existingItem!.valueForKey("photoOfItem") as? NSData
            itemQrCodeNSData = existingItem!.valueForKey("qrCodeImage") as? NSData
            folderName = existingItem!.folder
            println("folderName retrieved from core data is \(existingItem!.folder)")
            displayItemInfo()
            saveButton.title = "Done"
            
        }
        textViewToolbar.removeFromSuperview()
        titleTextField.delegate = self
        subtitleTextField.delegate = self
        notesTextView.inputAccessoryView = textViewToolbar
    }
    
    @IBAction func saveTapped(sender: AnyObject) {
        saveAll()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func actionButtonTapped(sender: UIBarButtonItem) {
        generateActionPopup(utilitiesHelper.convertQRCodeToData(qrCode!, jpeg: false), qrCodeImage: qrCode!, currentItemTitle: titleTextField.text)
    }
    
    @IBAction func trashTapped(sender: UIBarButtonItem) {
        var actionSheet = UIAlertController(title: "Trash", message: "Are you sure you want to delete this item?", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { action in
            let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context: NSManagedObjectContext = appDelegate.managedObjectContext!
    
            println("7")
            if self.existingItem != nil {
                println("6")
                context.deleteObject(self.existingItem!)
                println("just tried to delete the current existing object")
            } else if self.newItem != nil {
                println("5")
                context.delete(self.newItem)
            }
            println("4")
            var error: NSError? = nil
            if !context.save(&error) {
                abort()
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
            println("3")
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        println("2")
        actionSheet.popoverPresentationController?.barButtonItem = trashButton
        actionSheet.popoverPresentationController?.sourceView = self.view
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
        println("1")
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
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
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
            println("The folder name to be saved: \(folderName)")
            existingItem?.folder = folderName
            println("The folder name that was saved: \(folderName)")
        } else if existingItem == nil { //creating new item
            newItem = ItemCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
            newItem?.title = titleTextField.text
            newItem?.subtitle = subtitleTextField.text
            newItem?.notes = notesTextView.text
            newItem?.dateLastEdited = NSDate()
            newItem?.dateCreated = NSDate()
            println(folderName)
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

