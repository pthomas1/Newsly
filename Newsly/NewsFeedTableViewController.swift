//
//  NewsFeedTableViewController.swift
//  Newsly
//
//  Created by Peter Thomas on 4/28/17.
//  Copyright © 2017 Peter Thomas. All rights reserved.
//

import UIKit
import SafariServices

class NewsFeedTableViewController: UITableViewController {
    
    var newsAPI:NewsAPI = NewsAPI()

    var selectedSourceIds:Set<String>!
    var selectedSources:[NewsSource]? { return newsAPI.newsSources?.filter { self.selectedSourceIds?.contains($0.id) == true } }

    var sourceArticles = [String:Set<NewsArticle>]()
    var allArticles = [NewsArticle]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
        self.refreshControl?.addTarget(self, action: #selector(handlePullToRefresh(_:)), for: UIControlEvents.valueChanged)

        selectedSourceIds = Set((UserDefaults.standard.array(forKey: NewsSourcesTableViewController.selectedNewsSourceIdsDefaultsKey) as? [String]) ?? [])
        loadNewsSourcesAndArticles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSourcesForSelectedSourceIds()
    }

    // MARK: - Pull to refresh

    func handlePullToRefresh(_ refreshControl: UIRefreshControl) {
        guard let selectedSources = self.selectedSources else {
            logger.error("No selected sources")
            return
        }
        
        self.loadArticlesForSources(selectedSources, replaceExisting: true) {
            self.tableView.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
    // MARK: - Article management
    
    func loadArticlesForSources(_ sources:[NewsSource], replaceExisting:Bool, completed:@escaping () -> Void) {
        
        var loadedSourceArticles = replaceExisting ? [String:Set<NewsArticle>]() : sourceArticles
        
        let dispatchGroup = DispatchGroup()
        for source in sources {
            dispatchGroup.enter()
            self.newsAPI.loadArticles(source:source) { (articles, error) in
                defer { dispatchGroup.leave() }
                guard let articles = articles else { return }
                self.synchronized {
                    loadedSourceArticles[source.id] = (loadedSourceArticles[source.id] ?? Set<NewsArticle>()).union(articles)
                }
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.synchronized {
                self.sourceArticles = loadedSourceArticles
                self.populateAllArticles()
                completed()
            }
        }
    }

    func populateAllArticles() {
        synchronized {
            allArticles = sourceArticles.values.flatMap({$0}).sorted(by: { (left, right) -> Bool in
                return (left.publicationDate ?? Date(timeIntervalSince1970: 0)) > (right.publicationDate ?? Date(timeIntervalSince1970: 0))
            })
        }
    }
    
    func articleFor(indexPath:IndexPath) -> NewsArticle {
        var article:NewsArticle? = nil
        synchronized {
            guard indexPath.row < allArticles.count else { fatalError("Invalid index path") }
            article = allArticles[indexPath.row]
        }
        return article!
    }
    
    // MARK: - News source management
    
    func loadNewsSourcesAndArticles() {
        
        newsAPI.loadSources() { (error) in
            
            DispatchQueue.main.async {
                
                if let error = error {
                    logger.error("Error occurred while listing sources: \(error)")
                    let alert = UIAlertController(title: "Sources Error", message: "We were unable to download your news sources. Please try again later.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default))
                    self.present(alert, animated: true)
                    
                } else {
                    // if nothing is selected assume it should all be selected
                    if self.selectedSourceIds.count == 0 {
                        self.selectedSourceIds = Set(self.newsAPI.newsSources.map {$0.id})
                    }
                    
                    guard let selectedSources = self.selectedSources else {
                        logger.error("No selected sources")
                        return
                    }

                    self.loadArticlesForSources(selectedSources, replaceExisting: true) {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func updateSourcesForSelectedSourceIds() {
        
        // if the user made new selections we have to reload the content for them
        let newSelectedSourceIds = Set((UserDefaults.standard.array(forKey: NewsSourcesTableViewController.selectedNewsSourceIdsDefaultsKey) as? [String]) ?? [])
        
        let removedSources = selectedSourceIds.subtracting(newSelectedSourceIds)
        let insertedSources = newSelectedSourceIds.subtracting(selectedSourceIds)
        selectedSourceIds = newSelectedSourceIds
        
        // first remove all removed selections and reload the data
        synchronized {
            for removedSource in removedSources {
                sourceArticles.removeValue(forKey: removedSource)
            }
            populateAllArticles()
            self.tableView.reloadData()
        }

        // now load the content for the newly added sources
        loadArticlesForSources(insertedSources.flatMap({ newsSource(withID:$0) }), replaceExisting: false) {
            self.tableView.reloadData()
        }
    }

    func newsSource(withID:String) -> NewsSource? {
        return newsAPI.newsSources.first { $0.id == withID }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int = 0
        synchronized {
            count = allArticles.count
        }
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "newsArticleReuseIdentifier", for: indexPath) as? NewsArticleTableViewCell else { fatalError("Did not find NewsArticleTableViewCell in tableview") }

        let article = articleFor(indexPath: indexPath)
        cell.populate(article)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let article = articleFor(indexPath: indexPath)
        
        let safariViewController = SFSafariViewController(url: article.url, entersReaderIfAvailable: true)
        present(safariViewController, animated: true)
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "settingsSegueIdentifier" {
            return newsAPI.newsSources != nil
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let newsSources = newsAPI.newsSources else { fatalError("Cannot present source selector without news sources") }
        
        if segue.identifier == "settingsSegueIdentifier" {
            guard let viewController = segue.destination as? NewsSourcesTableViewController else { fatalError("Incorrect view controller type in segue") }
            viewController.newsSources = newsSources
            viewController.selectedSourceIds = Set(selectedSourceIds)
        }
    }
}
