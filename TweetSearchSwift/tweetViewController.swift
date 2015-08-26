//
//  tweetViewController.swift
//  Tweet-Search-Swift
//
//  Displays all saved tweets in table view and allows user to delete saved tweets from table and core data stack
//  In loading, the core data stack of entities 'Tweets' is loaded. The table view handler funcs parse through the 
//  local function and display the appropriate saved tweets.
//
//

import UIKit
import CoreData

var Savedtweets = [NSManagedObject]()

class tweetViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.loadTweets()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view handler funcs

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Savedtweets.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell", forIndexPath: indexPath) as! UITableViewCell

        
        // Load cell with corresponding indexpath.row
        let tweetCell = Savedtweets[indexPath.row]
        cell.textLabel!.text = tweetCell.valueForKey("text") as? String
        
        // User entity imageURL string to save twitter user profile pic
        var imageText = tweetCell.valueForKey("imageURL") as? String
        var imageURL:NSURL? = NSURL(string: imageText!)
        var data:NSData? = NSData(contentsOfURL: imageURL!)
        var image:UIImage? = UIImage(data: data!)
        // Set profile pic to cell image
        cell.imageView?.image = image

        
        
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete{

            // Remove proper entity from core data
            let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context:NSManagedObjectContext = appDel.managedObjectContext!
            context.deleteObject(Savedtweets[indexPath.row] as NSManagedObject)
            context.save(nil)

            // Remove cell from class array
            Savedtweets.removeAtIndex(indexPath.row)
            
            // Removev cell from tableview
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            
            
                
            

            
        }
    }
   
    // MARK: Core data func
    
    func loadTweets(){
        // Load saved tweet entities from core data
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Tweet")
        var error: NSError?
        
        let fetchedResults =
        managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [NSManagedObject]
        
        
        if let results = fetchedResults {
            var tweets = [NSManagedObject]()
            tweets = results
            Savedtweets = results
            
        } else {
            println("Could not fetch tweets \(error), \(error!.userInfo)")
        }
    }

}
