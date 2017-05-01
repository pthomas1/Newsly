//
//  NewsSourcesTableViewController.swift
//  Newsly
//
//  Created by Peter Thomas on 4/28/17.
//  Copyright © 2017 Peter Thomas. All rights reserved.
//

import UIKit

class NewsSourcesTableViewController: UITableViewController {

    static let selectedNewsSourceIdsDefaultsKey = "com.floodlightsoftware.selectedNewsSourceIds"
    
    var newsAPI:NewsAPI = NewsAPI()
    var newsSources:[NewsSource]!
    var selectedSourceIds:Set<String>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let newsSources = newsSources else { return 0 }
        return newsSources.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "sourceReuseIdentifier", for: indexPath) as? NewsSourceTableViewCell else { fatalError("No NewsSourceTableViewCell found") }
        guard let newsSources = newsSources else { fatalError("No news sources defined for table view cells") }
        guard indexPath.row < newsSources.count else { fatalError("Invalid index path for news source") }
        
        let newsSource = newsSources[indexPath.row]
        
        cell.populate(newsSource, isSelected:selectedSourceIds.contains(newsSource.id))
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let newsSources = newsSources else { fatalError("No news sources defined for table view cells") }
        guard indexPath.row < newsSources.count else { fatalError("Invalid index path for news source") }
        
        let newsSource = newsSources[indexPath.row]
        if selectedSourceIds.remove(newsSource.id) == nil {
            selectedSourceIds.insert(newsSource.id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
        
        UserDefaults.standard.set(Array(selectedSourceIds), forKey: NewsSourcesTableViewController.selectedNewsSourceIdsDefaultsKey)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
