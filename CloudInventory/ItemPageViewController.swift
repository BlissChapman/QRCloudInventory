import UIKit
import CoreData

class ItemPageViewController: UIViewController {
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    
    var qrCode: UIImage? {
        didSet {
            qrCodeImageView.image = qrCode
        }
    }
    var stringToEncode: String?
    lazy var utilitiesHelper = Helper()
    
    //All properties for updating an existing item's info
    var existingItem: CoreDataModel?
    var itemTitle: String?
    var itemSubtitle: String?
    var itemNotes: String?
    var itemPhoto: NSData?
    var itemQrCodeNSData: NSData?
    
    //All properties for creating a new item
    var newItem: CoreDataModel?
    
    
    override func viewWillAppear(animated: Bool) {
        
        //existingItem is set based on the table view row selected
        if existingItem != nil {
            itemTitle = existingItem!.title
            itemSubtitle = existingItem!.subtitle
            itemNotes = existingItem!.notes
            itemPhoto = existingItem!.valueForKey("photoOfItem") as? NSData
            itemQrCodeNSData = existingItem!.valueForKey("qrCodeImage") as? NSData
            
            displayItemInfo()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @IBAction func saveTapped(sender: AnyObject) {
        saveAll()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func actionButtonTapped(sender: UIBarButtonItem) {
        self.presentViewController(utilitiesHelper.generateActionPopup(utilitiesHelper.convertQRCodeToData(qrCode!), qrCodeImage: qrCode!, currentItemTitle: titleTextField.text), animated: true, completion: nil)
    }
    
    func displayItemInfo() {
        if itemQrCodeNSData != nil {
            qrCode = UIImage(data: itemQrCodeNSData!)
        }
        titleTextField.text = itemTitle
        subtitleTextField.text = itemSubtitle
        notesTextView.text = itemNotes
    }
    
    func saveAll() {
        let myAppDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let myContext: NSManagedObjectContext = myAppDelegate.managedObjectContext!
        let myEntity = NSEntityDescription.entityForName("InventoryItem", inManagedObjectContext: myContext)
        let frequency = NSFetchRequest(entityName: "InventoryItem")
        
        var qrCodeImageToSave: NSData?
        
        if existingItem != nil { //updating existing item
            existingItem?.title = titleTextField.text
            existingItem?.subtitle = subtitleTextField.text
            existingItem?.notes = notesTextView.text
        } else if existingItem == nil { //creating new item
            newItem = CoreDataModel(entity: myEntity!, insertIntoManagedObjectContext: myContext)
            newItem?.title = titleTextField.text
            newItem?.subtitle = subtitleTextField.text
            newItem?.notes = notesTextView.text
            
            //if qr code doesn't exist when save is tapped, generate a new one.
            if qrCode == nil {
                stringToEncode = utilitiesHelper.generateIdString(titleTextField.text, subtitle: subtitleTextField.text, notes: notesTextView.text)
                qrCode = utilitiesHelper.generateQRCodeForString(stringToEncode!)
                newItem?.idString = stringToEncode!
            }
            if qrCode != nil {
                var qrCodeNSData = utilitiesHelper.convertQRCodeToData(qrCode!)
                newItem!.qrCodeImage = qrCodeNSData
            }
        }
        
        myContext.save(nil)
    }
    
}

