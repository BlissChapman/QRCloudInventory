import UIKit
import CoreData

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
    
    var selectTitleAutomatically = true
    
    //All properties for updating an existing item's info - property observers update ui as necessary
    private var qrCode: UIImage? {
        didSet { qrCodeImageView.image = qrCode }
    }
    private var itemImage: UIImage? {
        didSet {
            pictureImageView.image = itemImage
            themeImageView.image = itemImage
        }
    }
    private lazy var utilitiesHelper = Helper()
    
    var existingItem: ItemCoreDataModel?
    private var itemTitle: String? {
        didSet {
            titleTextField.text = itemTitle
        }
    }
    private var itemSubtitle: String? {
        didSet { subtitleTextField.text = itemSubtitle }
    }
    private var itemNotes: String? {
        didSet { notesTextView.text = itemNotes }
    }
    private var itemPhoto: NSData? {
        didSet {
            if let imageRetrieved = itemPhoto {
                itemImage = UIImage(data: imageRetrieved)
            }
        }
    }
    private var itemQrCodeNSData: NSData? {
        didSet {
            if let qrCodeImageRetrieved = itemQrCodeNSData {
                qrCode = UIImage(data: qrCodeImageRetrieved)
            }
        }
    }
    private var tagNames: String? {
        get { return NSUserDefaults.standardUserDefaults().valueForKey("lastTagNameSelected") as? String }
        set { NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "lastTagNameSelected")
            NSUserDefaults.standardUserDefaults().synchronize() }
    }
    var indexOfCurrentItemInMyInventoryArray: Int? {
        get { return NSUserDefaults.standardUserDefaults().valueForKey("indexOfCurrentItemInMyInventoryArray") as? Int
        } set { NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "indexOfCurrentItemInMyInventoryArray")
            NSUserDefaults.standardUserDefaults().synchronize() }
    }
    
    //If the item is just being created
    private var newItem: ItemCoreDataModel?
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if indexOfCurrentItemInMyInventoryArray != nil {
            setAllPropertiesFromIndex(indexOfCurrentItemInMyInventoryArray!)
        } else if existingItem != nil {
            itemTitle = existingItem?.title
            itemSubtitle = existingItem?.subtitle
            itemNotes = existingItem?.notes
            itemPhoto = existingItem!.valueForKey("photoOfItem") as? NSData
            itemQrCodeNSData = existingItem!.valueForKey("qrCodeImage") as? NSData
            tagNames = existingItem!.tags
        }
        saveButton.title = "Done"
        textViewToolbar.removeFromSuperview()
        titleTextField.delegate = self
        if selectTitleAutomatically == true {
            titleTextField.becomeFirstResponder()
        }
        subtitleTextField.delegate = self
        notesTextView.inputAccessoryView = textViewToolbar
    }
    
    private func setAllPropertiesFromIndex(index: Int) {
        var myInventory = [AnyObject]()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        let itemFrequency = NSFetchRequest(entityName: "InventoryItem")
        var err: NSError?
        myInventory = context.executeFetchRequest(itemFrequency, error: &err)!
        
        existingItem = myInventory[index] as? ItemCoreDataModel
        
        if existingItem != nil {
            itemTitle = existingItem?.title
            itemSubtitle = existingItem?.subtitle
            itemNotes = existingItem?.notes
            itemPhoto = existingItem?.valueForKey("photoOfItem") as? NSData
            itemQrCodeNSData = existingItem?.valueForKey("qrCodeImage") as? NSData
            tagNames = existingItem?.tags
        }
    }
    
    // MARK: - IBActions
    @IBAction private func saveTapped(sender: AnyObject) {
        saveAll()
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "lastTagNameSelected")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "indexOfCurrentItemInMyInventoryArray")
        NSUserDefaults.standardUserDefaults().synchronize()
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction private func cancelTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "lastTagNameSelected")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "indexOfCurrentItemInMyInventoryArray")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction private func actionButtonTapped(sender: UIBarButtonItem) {
        generateActionPopup(utilitiesHelper.convertQRCodeToData(qrCode!, jpeg: false), qrCodeImage: qrCode!, currentItemTitle: titleTextField.text)
    }
    
    @IBAction private func trashTapped(sender: UIBarButtonItem) {
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
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction private func cameraTapped(sender: AnyObject) { createPhotoActionSheet() }
    @IBAction private func doneTyping(sender: UIBarButtonItem) { notesTextView.resignFirstResponder() }
    
    internal func textFieldShouldReturn(textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
    
    // MARK: - Saving Data
    private func saveAll() {
        if titleTextField.text == nil || titleTextField.text == "" || titleTextField.text == " " {
            var noTitleAlert = UIAlertController(title: "Title is required", message: "Please add a title to your item.", preferredStyle: .Alert)
            noTitleAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            presentViewController(noTitleAlert, animated: true, completion: nil)
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
            existingItem?.tags = tagNames
        } else if existingItem == nil { //creating new item
            newItem = ItemCoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
            newItem?.title = titleTextField.text
            newItem?.subtitle = subtitleTextField.text
            newItem?.notes = notesTextView.text
            newItem?.dateLastEdited = NSDate()
            newItem?.dateCreated = NSDate()
            newItem?.tags = tagNames
            if let pngImage = UIImageJPEGRepresentation(itemImage, 1.0) {
                newItem?.photoOfItem = pngImage
            }
            
            //if qr code doesn't exist when save is tapped, generate a new one.
            if qrCode == nil {
                let qrTuple = utilitiesHelper.generateQRCodeForString(titleTextField.text, subtitle: subtitleTextField.text, notes: notesTextView.text, fromString: nil)
                qrCode = qrTuple.qrCode
                newItem?.idString = qrTuple.encodedString
            }
            if qrCode != nil {
                var qrCodeNSData = utilitiesHelper.convertQRCodeToData(qrCode!, jpeg: true)
                newItem!.qrCodeImage = qrCodeNSData
            }
        }
        myContext.save(nil)
    }
    
    // MARK: - Other
    private func generateActionPopup(qrCodeToPrint: NSData, qrCodeImage: UIImage, currentItemTitle: String) {
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
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - Choosing Photo
    private func createPhotoActionSheet() {
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
            photoActionSheet.popoverPresentationController?.barButtonItem = cameraButton
            photoActionSheet.popoverPresentationController?.sourceView = view
            
            presentViewController(photoActionSheet, animated: true, completion: nil)
        } else {
            noCameraPermissionAlert()
        }
    }
    
    
    private func takeNew() {
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
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    private func selectFromLibrary() {
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
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    private func noCameraAlert() {
        var noCameraAlert = UIAlertController(title: "Error", message: "Device has no camera", preferredStyle: .Alert)
        noCameraAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        presentViewController(noCameraAlert, animated: true, completion: nil)
    }
    
    private func noCameraPermissionAlert() {
        var noCameraPermissionAlert = UIAlertController(title: "Permission Required", message: "We don't have permission to use your camera or photos.  Please revise your privacy settings. ", preferredStyle: .Alert)
        noCameraPermissionAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        noCameraPermissionAlert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { action in
            var appSettings: NSURL = NSURL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.sharedApplication().openURL(appSettings)
        }))
        presentViewController(noCameraPermissionAlert, animated: true, completion: nil)
    }
    
    internal func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        itemImage = info[UIImagePickerControllerEditedImage] as? UIImage
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    internal func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Popover Delegate
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
            case "TagSelection":
                if let vc = segue.destinationViewController as? TagSelectionTableViewController {
                    if let ppc = vc.popoverPresentationController {
                        ppc.delegate = self
                    }
                }
            default: break
            }
        }
    }
    
}

