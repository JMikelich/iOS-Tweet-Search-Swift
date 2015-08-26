//
//  ViewController.swift
//  Tweet-Search-Swift
//
//  Handles initial view. Allows user to either type in search term and search all tweets
//  or view all saved tweets
//
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        // Handle searchViewController segue and save user searchterm
        if(segue!.identifier == "SearchTweets"){
            let searchVC = segue!.destinationViewController as! searchViewController
            searchVC.searchTerm = textField.text
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func searchTweets(sender: UIButton) {
        if(textField.text != ""){
            // Only segue to searchViewController if the search field isn't empty
            self.performSegueWithIdentifier("SearchTweets", sender: self)
        }
    }


}

