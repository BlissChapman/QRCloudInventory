//
//  TextAlignmentViewController.swift
//  CloudInventory
//
//  Created by Bliss Chapman on 3/7/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import UIKit

class TextAlignmentViewController: UIViewController {
    
    override var preferredContentSize: CGSize {
        get {
            if presentingViewController != nil {
                return CGSize(width: 120, height: 40)
            } else {
                return super.preferredContentSize
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func optionSelected(sender: UIButton) {
        //notesTextView.text = "alignLeft was tapped"
        switch sender.currentTitle! {
        case "AlignLeft":
            println("alignLeft!")
            //UITextViewAlignment
        case "AlignCenter":
            println("alignCenter!")
        case "AlignRight":
            println("alignRight!")
        default:
            println("nothing selected")
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
