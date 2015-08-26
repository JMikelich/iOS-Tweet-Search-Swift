//
//  searchViewController.swift
//  Tweet-Search-Swift
//
//  Takes input of search term from the initial view controller and queries twitter. Once twitter respondes with found tweets
//  the tableview updates with the new information and displays found tweets. User has ability to select tweets they wish to save.
//  When the user leaves this view, the tweets are stored into core data under the entity 'Tweets'
//  
//

import UIKit
import Accounts
import Social
import CoreData

enum UYLTwitterSearchState {
    case UYLTwitterSearchStateLoading
    case UYLTwitterSearchStateNotFound
    case UYLTwitterSearchStateRefused
    case UYLTwitterSearchStateFailed
    case UYLTwitterSearchStateComplete

}

class searchViewController: UITableViewController {

    // MARK: Vars initialization
    var searchTerm = ""

    // Twitter search vars
    var account : ACAccount?
    let accountStore = ACAccountStore()
    var searchState:UYLTwitterSearchState!
    var connection:NSURLConnection!
    var buffer:NSMutableData!
    var results:NSMutableArray!
    
    // Local data array of save tweets
    var selectedTweetData:NSMutableDictionary!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize twitter query
        self.loadQuery()
        
        // Initialize local tweet array
        selectedTweetData = NSMutableDictionary()
    }

    override func viewWillDisappear(animated: Bool) {
        
        // Transfer saved tweets into core data stack
        self .saveTweetsIntoCoreData()
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view handler funcs

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Set numberOfRows for count of results
        
        if(self.results != nil){
            // Check of tweet search has concluded
            
            var count:Int? = self.results.count
        
            if(count < 1){
                // Ensure atleast 1 row
                count = 1
            }
                return count!

        }
        else{
            return 1
        }
        
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell", forIndexPath: indexPath) as! UITableViewCell
        
        var count:Int
        
        if(self.results != nil){
            // Handle case where query is incomplete
            count = self.results.count
        }
        else{
            count = 0;
        }
        
        if(count == 0 && indexPath.row == 0){
            // Query has not completed yet, display loading for user
            cell.textLabel?.text = "Loading"
            return cell
        }
        
        // Query is complete, process all found tweets from search
        var tweet:NSDictionary = self.results[indexPath.row] as! NSDictionary
        
        cell.textLabel?.text = tweet["text"] as? String
        
        // Parse through JSON data for profile pic and display
        var imageURL:NSURL? = NSURL(string: tweet["user"]?.valueForKey("profile_image_url") as! String)
        var data:NSData? = NSData(contentsOfURL: imageURL!)
        var image:UIImage? = UIImage(data: data!)
        cell.imageView?.image = image
        
        if(selectedTweetData .objectForKey(String(indexPath.row)) == nil){
            // Handle dynamic table loading to ensure checkmarks (or lack there of) are saved while user scrolls table
            cell.accessoryType = .None
        }
        else{
            cell.accessoryType = .Checkmark
        }
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Handle user selected tweets
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let tweet:NSDictionary = self.results[indexPath.row] as! NSDictionary
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if(cell?.accessoryType != .Checkmark){
            cell?.accessoryType = .Checkmark
            
            if(selectedTweetData .objectForKey(String(indexPath.row)) != nil){
                // Tweet is already saved
            }
            else{
                // Add tweet to local data array
                selectedTweetData .setObject(tweet, forKey: String(indexPath.row))
            }
        }
        else{
            // Deselect row and remove tweet from local data array
            cell?.accessoryType = .None
            selectedTweetData .removeObjectForKey(String(indexPath.row))
            
        }
    }
    
    // MARK: Twitter search handler funcs
    
    func loadQuery(){
        // Initialize search state
        searchState = UYLTwitterSearchState.UYLTwitterSearchStateLoading

        //let encodedSearch = searchTerm.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let accountType = self.accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        // Prompt the user for permission to their twitter account stored in the phone's settings
        self.accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            if granted {
                // Load user twitter account
                let twitterAccounts = self.accountStore.accountsWithAccountType(accountType)

                if twitterAccounts?.count == 0
                {
                    // Twitter is not logged in
                    self.searchState = UYLTwitterSearchState.UYLTwitterSearchStateNotFound
                    println("User not logged into twitter")
                }
                else {
                    // User is logged into twitter on device
                    let twitterAccount = twitterAccounts[0] as! ACAccount
                    
                    // Load twitter search url
                    let url = "https://api.twitter.com/1.1/search/tweets.json"
                    // Define parameters for search as defined by twitter API
                    var param = [
                        "q": self.searchTerm,
                        "result_type": "recent",
                        "count": "100"
                    ]
                    
                    // Load request
                    let slRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, URL: NSURL(string: url), parameters: param)
                    // Load twitter account into request
                    slRequest.account = twitterAccount
                   
                    // Prepare request for connection
                    let request = slRequest .preparedURLRequest()
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        // Define connection and initalize
                        self.connection = NSURLConnection(request: request, delegate: self)
                        [UIApplication .sharedApplication().networkActivityIndicatorVisible = true]
                        });

                    
                }
                
            }
            else {
                self.searchState = UYLTwitterSearchState.UYLTwitterSearchStateRefused
                println("Access denied by user")

            }
        }
        
    }

    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        // Connection successful and response is recieved!
        self.buffer = NSMutableData()
        
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        // Transfer data into local buffer array
        self.buffer .appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {

        // Tweet search completed. Load JSON results
        var jsonError: NSError?
        let jsonResults = NSJSONSerialization.JSONObjectWithData(self.buffer, options: nil, error: &jsonError) as! NSDictionary
        

        
        // Save statuses for table use
        self.results = jsonResults["statuses"] as! NSMutableArray
        if(self.results.count == 0){
            println("No results found")
        }
        
        // Reload table data
        self.tableView .reloadData()
        self.tableView .flashScrollIndicators()
        
        // Reset connection vars
        self.searchState = UYLTwitterSearchState.UYLTwitterSearchStateComplete
        self.connection = nil


    }
    
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        // Search failed
        self.searchState = UYLTwitterSearchState.UYLTwitterSearchStateFailed
    }
    
    
   
    // MARK: Core data func
    
    func saveTweetsIntoCoreData(){
       
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Grab app context
        let managedContext = appDelegate.managedObjectContext!
        
        for (key, value) in selectedTweetData {
            // Loop through local data array and save tweet data into entity type on data stack
            let text = value["text"] as! String
            
            let user = value["user"] as! NSDictionary
            let url = user["profile_image_url"] as! String
            
            // Load defined core data type
            let entity =  NSEntityDescription.entityForName("Tweet",
                inManagedObjectContext:
                managedContext)
            let tweet = NSManagedObject(entity: entity!,
                insertIntoManagedObjectContext:managedContext)
            
            // Input data
            tweet.setValue(text, forKey: "text")
            tweet.setValue(url, forKey: "imageURL")
            
            // Complete save and handle potential erro
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
    
            
            
        }
        
    }

}
