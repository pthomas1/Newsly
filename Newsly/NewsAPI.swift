//
//  NewsAPI.swift
//  Newsly
//
//  Created by Peter Thomas on 4/28/17.
//  Copyright © 2017 Peter Thomas. All rights reserved.
//

import UIKit

enum NewsAPIErrors:Error {
    case invalidResponse
}

class NewsAPI: NSObject {
    
    let url = "https://newsapi.org/v1/"
    let apiKey:String
    var newsSources:[NewsSource]!
    
    override init() {
        
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let keysDictionary = NSDictionary(contentsOfFile: path) else { fatalError("You must provide a Keys.plist") }
        
        guard let apiKey = keysDictionary["newsAPIKey"] as? String else { fatalError("You must include a newsAPIKey in Keys.plist -- from https://newsapi.org/") }

        self.apiKey = apiKey
        
        super.init()
    }
    
    func loadSources( completed: ((_ error:Error?) -> Void)?=nil) {
        
        guard newsSources == nil else {
            completed?(nil)
            return
        }
        
        let sourcesURL = URL(string:url.appending("sources?language=en"))!
        
        let task = URLSession.shared.dataTask(with: sourcesURL) { (data, response, error) in
            
            if let data = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let dictionary = jsonObject as? NSDictionary else { throw NewsAPIErrors.invalidResponse }
                    guard let sourceDictionaries = dictionary["sources"] as? [NSDictionary] else { throw NewsAPIErrors.invalidResponse }
                    
                    var newsSources = [NewsSource]()
                    for sourceDictionary in sourceDictionaries {                        
                        newsSources.append(try NewsSource.create(dictionary:sourceDictionary))
                    }
                    
                    self.newsSources = newsSources

                    logger.debug("Downloaded \(self.newsSources.count) news sources")
                    completed?(nil)

                } catch {
                    logger.error("Exception occurred while processing sources response: \(error)")
                    completed?(error)
                }
            }
        }
        
        task.resume()
    }
    
    func loadArticles(source:NewsSource, completed: ((_ articles:[NewsArticle]?, _ error:Error?) -> Void)?=nil) {

        guard let sortBy:String = ["latest", "top", "popular"].first(where:{ source.sortableBy.contains($0) }) else {
            completed?([], nil)
            return
        }
        
        let sourcesURL = URL(string:url.appending("articles?sortBy=\(sortBy)&source=\(source.id)&apiKey=\(apiKey)"))!
        
        let task = URLSession.shared.dataTask(with: sourcesURL) { (data, response, error) in
            
            if let data = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let dictionary = jsonObject as? NSDictionary else { throw NewsAPIErrors.invalidResponse }
                    guard let articleDictionaries = dictionary["articles"] as? [NSDictionary] else { throw NewsAPIErrors.invalidResponse }
                    
                    var articles = [NewsArticle]()
                    for articleDictionary in articleDictionaries {
                        do {
                            articles.append(try NewsArticle.create(dictionary:articleDictionary, source:source))
                        } catch {
                            logger.error("Exception occurred while creating article \(articleDictionary)")
                        }
                    }

                    logger.debug("Downloaded \(articles.count) articles for \(source.id)")
                    completed?(articles, nil)

                } catch {
                    logger.error("Exception occurred while processing articles response: \(error)")
                    completed?(nil, error)
                }
            }
        }
        
        task.resume()
    }
}

struct NewsArticle: Hashable {
    
    let author:String?
    let title:String
    let description:String
    let url:URL
    let imageURL:URL?
    let publicationDate:Date?
    let source:NewsSource
    
    static func create(dictionary articleDictionary:NSDictionary, source:NewsSource) throws -> NewsArticle {
        guard let title = articleDictionary["title"] as? String else {
            logger.error("Invlaid title")
            throw NewsAPIErrors.invalidResponse
        }
        guard let description = articleDictionary["description"] as? String else {
            logger.error("Invlaid description")
            throw NewsAPIErrors.invalidResponse
        }
        guard let urlString = articleDictionary["url"] as? String else {
            logger.error("Invlaid url string")
            throw NewsAPIErrors.invalidResponse
        }
        guard let url = URL(string:urlString) else {
            logger.error("Invlaid url")
            throw NewsAPIErrors.invalidResponse
        }

        var author = (articleDictionary["author"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let splitAuthor = author?.components(separatedBy: .whitespacesAndNewlines).filter { $0.characters.count > 0 }
        author = splitAuthor?.joined(separator: " ")
        
        var imageURL:URL? = nil
        if let imageURLString = articleDictionary["urlToImage"] as? String {
            imageURL = URL(string:imageURLString)
        }
        
        let publicationDateString = articleDictionary["publishedAt"] as? String
        let publicationDate = publicationDateString?.dateFromISO8601
        return NewsArticle(author: author, title: title, description: description, url: url, imageURL: imageURL, publicationDate: publicationDate, source:source)
    }
    
    public var hashValue: Int { return url.hashValue }
    
    public static func ==(lhs: NewsArticle, rhs: NewsArticle) -> Bool {
        return lhs.url == rhs.url
    }
}



struct NewsSource {
    
    let id:String
    let name:String
    let description:String
    
    let url:URL
    let category:String
    
    let language:String
    let country:String
    
    let sortableBy:[String]
    
    static func create(dictionary sourceDictionary:NSDictionary) throws -> NewsSource {

        guard let id = sourceDictionary["id"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let name = sourceDictionary["name"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let description = sourceDictionary["description"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let urlString = sourceDictionary["url"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let category = sourceDictionary["category"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let language = sourceDictionary["language"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let country = sourceDictionary["country"] as? String else { throw NewsAPIErrors.invalidResponse }
        guard let sortableBy = sourceDictionary["sortBysAvailable"] as? [String] else { throw NewsAPIErrors.invalidResponse }
        guard let newsSourceURL = URL(string:urlString) else { throw NewsAPIErrors.invalidResponse }
        
        return NewsSource(id: id, name: name, description: description, url: newsSourceURL,
                          category: category, language: language, country: country, sortableBy: sortableBy)
        

    }
}

extension Formatter {
    static let iso8601WithMilliseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    static let iso8601NoMilliseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return formatter
    }()

}

extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601WithMilliseconds.date(from: self) ?? Formatter.iso8601NoMilliseconds.date(from: self)
    }
}
