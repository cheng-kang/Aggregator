//
//  SubscribeViewController.swift
//  Aggregator
//
//  Created by Ant on 29/01/2017.
//  Copyright © 2017 Lahk. All rights reserved.
//

import UIKit
import CoreData

func parseChanelURL(url: String) -> String {
    return url.replacingOccurrences(of: "onecolontwoslash", with: "://").replacingOccurrences(of: "onedot", with: ".").replacingOccurrences(of: "oneslash", with: "/")
    
}

class SubscribeViewController: UIViewController {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var tbl: UITableView!
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func create(_ sender: UIButton) {
        let vc = NewChannelViewController.vc()
        self.present(vc, animated: true, completion: nil)
    }
    
    var context: NSManagedObjectContext!{
        return (UIApplication.shared.delegate as? AppDelegate)?
            .persistentContainer.viewContext
    }
    
    var subNames: [String] = [String]()
    var subUrls: [String] = [String]()
    var subTitles: [String] = [String]()
    var channels: [String] = [String]()
    var urls: [String] = [String]() {
        didSet {
            self.tbl.reloadData()
        }
    }
    var titles: [String] = [String]()
    class func vc(subChannels: [SubChannels]) -> SubscribeViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "Subscribe") as! SubscribeViewController

        for item in subChannels {
            vc.subNames.append(item.name!)
            vc.subUrls.append(item.url ?? "")
            vc.subTitles.append(item.title ?? "")
        }
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tbl.dataSource = self
        self.tbl.delegate = self
        
//        self.channels.append("测试")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let pusherApp = App(id: "8b68feb8-c834-4049-9dd7-819461c70a88")
        
        pusherApp.request(using: GeneralRequest(method: "GET", path: "/apps/\(pusherApp.id)/feeds")) { result in
            switch result {
            case .success(let data):
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    return
                }
                
                guard let json = jsonObject as? [String: Any] else {
                    return
                }
                
                let feeds = json["feeds"] as! [[String: Any]]
                self.channels.removeAll()
                self.titles.removeAll()
                self.urls.removeAll()
                for item in feeds {
                    if !(item["name"] as! String).contains("guid") && (item["name"] as! String) != "playground" {
                        self.channels.append(item["name"] as! String)
                        let arr = (item["name"] as! String).components(separatedBy: "andurl")
                        self.titles.append(arr[0])
                        self.urls.append(parseChanelURL(url: arr[1]))
                    }
                }
            case .failure(let err):
                print(err)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tbl.reloadData()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            self.tbl.reloadData()
        })
    }
}

extension SubscribeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.subNames.contains(self.channels[indexPath.row]) {
            self.subNames.remove(at: self.subNames.index(of: self.channels[indexPath.row])!)
            tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.6)
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubChannels")
            fetchRequest.predicate = NSPredicate(format: "title == %@", self.channels[indexPath.row])
            if let result = try? context.fetch(fetchRequest) {
                for object in result {
                    context.delete(object as! NSManagedObject)
                }
            }
        } else {
            self.subNames.append(self.channels[indexPath.row])
            tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.9)
            
            let channel = SubChannels(context: context)
            channel.title = self.titles[indexPath.row]
            channel.url = self.urls[indexPath.row]
            channel.name = self.channels[indexPath.row]
            channel.lastId = ""
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.urls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") as! ChannelCell
        
        cell.nameLbl.text = self.titles[indexPath.row]
        
        if self.subNames.contains(self.channels[indexPath.row]) {
            cell.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.9)
        } else {
            cell.backgroundColor = UIColor(colorLiteralRed: 234/255, green: 81/255, blue: 64/255, alpha: 0.6)
        }
        
        return cell
    }
}
