//
//  ViewController.swift
//  Aggregator
//
//  Created by Ant on 28/01/2017.
//  Copyright © 2017 Lahk. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

/**
 The html replacement regular expression
 */
let htmlReplaceString: String = "<[^>]+>"

extension NSString {
    /**
     Takes the current NSString object and strips out HTML using regular expression. All tags get stripped out.
     
     :returns: NSString html text as plain text
     */
    func stripHTML() -> NSString {
        return (self.replacingOccurrences(of: htmlReplaceString, with: "", options: .regularExpression, range: NSRange(location: 0,length: self.length)) as NSString).replacingOccurrences(of: "\"", with: "\'") as NSString
    }
}

extension String {
    /**
     Takes the current String struct and strips out HTML using regular expression. All tags get stripped out.
     
     :returns: String html text as plain text
     */
    func stripHTML() -> String {
        return self.replacingOccurrences(of: htmlReplaceString, with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "\"", with: "\'")
    }
}

func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

class ChannelsViewController: UIViewController {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var tbl: UITableView!
    @IBAction func addChannel(_ sender: UIButton) {
        let vc = SubscribeViewController.vc(subChannels: channels)
        self.present(vc, animated: true, completion: nil)
    }
    
    var context: NSManagedObjectContext!{
        return (UIApplication.shared.delegate as? AppDelegate)?
            .persistentContainer.viewContext
    }
    
    var channels: [SubChannels] = [SubChannels]()
    
    let pusherApp = App(id: "8b68feb8-c834-4049-9dd7-819461c70a88")
    var subscribes: [ResumableSubscription] = [ResumableSubscription]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tbl.dataSource = self
        self.tbl.delegate = self
        self.tbl.tableFooterView = UIView()

//        pusherApp.request(using: GeneralRequest(method: "GET", path: "https://elifesciences.org/rss/recent.xml"), completionHandler: { result in
//            switch result {
//            case .success(let data):
//                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
//                    return
//                }
//                
//                guard let json = jsonObject as? [String: Any] else {
//                    return
//                }
//                
//                let feeds = json["feeds"] as! [[String: Any]]
                
//                let xmlData = data.dataUsingEncoding(String.Encoding.utf8)!
//                let parser = XMLParser(data: xmlData)
//                
//                parser.delegate = self
//                
//                parser.parse()
//                print(xmlData)
//            case .failure(let err):
//                print(err)
//            }
//            
//        })
        
        //        let channel = SubChannels(context: context)
        //        channel.name = "AngularJS"
        //        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        
//
//        pusherApp.request(using: GeneralRequest(method: "GET", path: "/apps/\(pusherApp.id)/feeds")) { result in
//            switch result {
//            case .success(let data):
//                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
//                    return
//                }
//                
//                guard let json = jsonObject as? [String: Any] else {
//                    return
//                }
//                
//                let feeds = json["feeds"] as! [[String: Any]]
//                
//                print(feeds)
//            case .failure(let err):
//                print(err)
//            }
//        }
//        rssTest()
        
        
    }
    
    func rssTest() {
        
        Alamofire.request("https://elifesciences.org/rss/recent.xml").responseRSS() { (response) -> Void in
            if let feed: RSSFeed = response.result.value {
                print(feed)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let channelsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SubChannels")
        do {
            let fetchedChannels = try context.fetch(channelsFetch) as! [SubChannels]
            self.channels = fetchedChannels
            
            for item in subscribes {
                item.changeState(to: .ended)
            }
            subscribes.removeAll()
            
            for item in channels {
                subscribes.append(pusherApp.feed(item.name!).subscribe(
                    lastEventId: item.lastId == "" ? nil : item.lastId,
                    onOpen: {
                        print("Pusher Connection Open")
                },
                    onResuming: {
                        print("Pusher Connection Resume")
                },
                    onAppend: { (itemId, headers, newItem) in
                        // parse feed item and download the page then save to core data
                        
                        if (newItem as? [String: String]) == nil {
                            return
                        }
                        let newItemData = newItem as! [String: String]
                        
                        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "Articles")

                        var a = [Any]()
                        if let result = try? self.context.fetch(fetchRequest1) {
                            
                            print(result)
                            a.append(contentsOf: result)
                        }
                        print(a)
                        
                        
                        let articlesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Articles")
                        articlesFetch.predicate = NSPredicate(format: "guid == %@", newItemData["guid"]!)
                        
                        do {
                            let fetchedArticles = try self.context.fetch(articlesFetch) as! [Articles]
                            if fetchedArticles.count == 0 {
                                
                                let article = Articles(context: self.context)
                                article.channel = item.name
                                article.date = newItemData["date"]
                                article.guid = newItemData["guid"]
                                article.itemId = itemId
                                article.title = newItemData["title"]
                                article.snippet = newItemData["desc"]
                                article.url = newItemData["url"]
                                article.read = false
                                (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
                            }
                            self.tbl.reloadData()
                        } catch {
                            fatalError("Failed to fetch channels: \(error)")
                        }
                },
                    onError: { (err) in
                        print("Error: ", err)
                }))
                
                
                let url = item.url!
                
                Alamofire.request(url).responseRSS() { (response) -> Void in
                    if let feed: RSSFeed = response.result.value {
                        //do something with your new RSSFeed object!
                        self.pusherApp.feed(item.title! + "guid").fetchOlderItems(from: nil, limit: 100, completionHandler: { (result) in
                            
                            switch result {
                            case .success(let data):
                                var guids = [String]()
                                
                                for pair in data {
                                    guids.append(pair["data"] as! String)
                                }
                                
                                for feeditem in feed.items {
                                    if !guids.contains(feeditem.guid ?? "") {
                                        if feeditem.title != nil && feeditem.title != "" {
                                            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Articles")
                                            fetch.fetchLimit = 1
                                            fetch.predicate = NSPredicate(format: "guid == %@", feeditem.guid ?? "")
                                            
                                            do {
                                                let fetchedArticles = try self.context.fetch(fetch) as! [Articles]
                                                if fetchedArticles.count == 0 {
                                                    let desc = feeditem.itemDescription?.stripHTML() ?? ""
                                                    // get the chunk
                                                    var chunk: String!
                                                    if desc.characters.count < 700 {
                                                        chunk = desc.substring(to: desc.endIndex)
                                                    } else {
                                                        chunk = desc.substring(to: desc.index(desc.startIndex, offsetBy: 700))
                                                    }
                                                    
                                                    let dict = [
                                                        "title": feeditem.title!,
                                                        "guid": feeditem.guid ?? "",
                                                        "url": feeditem.link ?? "",
                                                        "date": feeditem.pubDate?.description(with: Locale.current) ?? "",
                                                        "desc": chunk
                                                    ] as [String : Any]
                                                    self.pusherApp.feed(item.name!).append(item: dict)
                                                    self.pusherApp.feed(item.title!+"guid").append(item: feeditem.guid ?? "")
                                                }
                                            } catch {
                                                fatalError("Failed to fetch: \(error)")
                                            }
                                        }
                                    }
                                }
                                
                            case .failure(let err):
                                print(err)
                            }

                        })
                    } else {
                        print("test")
                    }
                }
            }
            self.tbl.reloadData()
        } catch {
            fatalError("Failed to fetch channels: \(error)")
        }
    }

}

extension ChannelsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChannelViewController.vc(channel: self.channels[indexPath.row].name!)
        self.present(vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") as! ChannelCell
        
        cell.nameLbl.text = self.channels[indexPath.row].title
        cell.followerLbl.text = "followers:"+" 1"
        
        let unreadArticlesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Articles")
        unreadArticlesFetch.fetchLimit = 1
        unreadArticlesFetch.predicate = NSPredicate(format: "(channel == %@) AND (read == false)", self.channels[indexPath.row].name!)
        
        do {
            let fetchedArticles = try context.fetch(unreadArticlesFetch) as! [Articles]
            if fetchedArticles.count != 0 {
                cell.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.9)
            } else {
                cell.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.6)
            }
        } catch {
            fatalError("Failed to fetch channels: \(error)")
        }
        
        return cell
    }
}

