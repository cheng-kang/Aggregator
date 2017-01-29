//
//  NewChannelViewController.swift
//  Aggregator
//
//  Created by Ant on 29/01/2017.
//  Copyright © 2017 Lahk. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

func encodeURL(url: String) -> String {
    return url.replacingOccurrences(of: "://", with: "onecolontwoslash").replacingOccurrences(of: "/", with: "oneslash").replacingOccurrences(of: ".", with: "onedot")
}
class NewChannelViewController: UIViewController {

    @IBOutlet weak var urlInput: UITextField!
    @IBOutlet weak var warningMsg: UILabel!
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    class func vc() -> NewChannelViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NewChannel") as! NewChannelViewController
        
        return vc
    }
    
    var context: NSManagedObjectContext!{
        return (UIApplication.shared.delegate as? AppDelegate)?
            .persistentContainer.viewContext
    }
    
    let pusherApp = App(id: "8b68feb8-c834-4049-9dd7-819461c70a88")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(NewChannelViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }

    @IBAction func create(_ sender: UIButton) {
        let url = self.urlInput.text!
        
        Alamofire.request(url).responseRSS() { (response) -> Void in
            if let feed: RSSFeed = response.result.value {
//                print(feed)
                if feed.title == "eLife" {
                    self.warningMsg.text = "Warning: Existing Feed"
                    self.warningMsg.alpha = 1
                    UIView.animate(withDuration: 3, delay: 1, options: [.curveEaseOut], animations: {
                        self.warningMsg.alpha = 0
                    }, completion: nil)
                    
                    return
                }
                
                self.pusherApp.feed((feed.title ?? "")+"andurl"+encodeURL(url: url)).fetchOlderItems(from: nil, limit: 1, completionHandler: { (result) in
                    switch result {
                    case .success(let data):
                        if data.count == 0 {
                            self.pusherApp.feed((feed.title ?? "")+"andurl"+encodeURL(url: url)).append(item: "Open Channel")
                            
                            let channel = SubChannels(context: self.context)
                            channel.title = feed.title
                            channel.url = url
                            channel.name = (feed.title ?? "")+"andurl"+encodeURL(url: url)
                            channel.lastId = ""
                            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
                            
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.warningMsg.text = "Warning: Existing Feed"
                            self.warningMsg.alpha = 1
                            UIView.animate(withDuration: 3, delay: 1, options: [.curveEaseOut], animations: {
                                self.warningMsg.alpha = 0
                            }, completion: nil)
                        }
                    case .failure(let err):
                        print(err)
                    }
                })
            } else {
                self.warningMsg.text = "Warning: In-valid Feed URL"
                self.warningMsg.alpha = 1
                UIView.animate(withDuration: 3, delay: 1, options: [.curveEaseOut], animations: {
                    self.warningMsg.alpha = 0
                }, completion: nil)
            }
        }
    }

}
