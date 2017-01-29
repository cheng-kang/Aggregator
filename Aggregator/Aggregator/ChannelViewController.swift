//
//  ChannelViewController.swift
//  Aggregator
//
//  Created by Ant on 29/01/2017.
//  Copyright © 2017 Lahk. All rights reserved.
//

import UIKit
import CoreData

class ChannelViewController: UIViewController {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var tbl: UITableView!
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var context: NSManagedObjectContext!{
        return (UIApplication.shared.delegate as? AppDelegate)?
            .persistentContainer.viewContext
    }
    
    var channel: String!
    var articles: [Articles] = [Articles]() {
        didSet {
            self.tbl.reloadData()
        }
    }
    var unreadCount: Int = 0
    
    class func vc(channel: String) -> ChannelViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "Channel") as! ChannelViewController
        vc.channel = channel
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tbl.dataSource = self
        self.tbl.delegate = self
        self.tbl.tableFooterView = UIView()
        
        self.titleLbl.text = self.channel.components(separatedBy: "andurl")[0]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let articlesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Articles")
        articlesFetch.predicate = NSPredicate(format: "channel == %@", self.channel)
        
        do {
            let fetchedArticles = try context.fetch(articlesFetch) as! [Articles]
            self.articles = fetchedArticles
        } catch {
            fatalError("Failed to fetch channels: \(error)")
        }
    }

}

extension ChannelViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell") as! ArticleCell
        
        cell.titleLbl.text = self.articles[indexPath.row].title
        cell.dateLbl.text = self.articles[indexPath.row].date
        cell.snippet.text = self.articles[indexPath.row].snippet
        
        if self.articles[indexPath.row].read {
            cell.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.6)
        } else {
            cell.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.9)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ArticleViewController.vc(article: self.articles[indexPath.row])
        self.present(vc, animated: true, completion: {
            self.articles[indexPath.row].read = true
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        })
    }
}
