//
//  ArticleViewController.swift
//  Aggregator
//
//  Created by Ant on 29/01/2017.
//  Copyright © 2017 Lahk. All rights reserved.
//

import UIKit

class ArticleViewController: UIViewController {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var webView: UIWebView!
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var article: Articles!
    
    class func vc(article: Articles) -> ArticleViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "Article") as! ArticleViewController
        vc.article = article
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.titleLbl.text = self.article.title
//        self.webView.loadHTMLString(self.article.content!, baseURL: nil)
        self.webView.loadRequest(URLRequest(url: URL(string: article.url!)!))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
