//
//  ViewController.swift
//  CPAProxyApp
//
//  Created by Cesar on 9/18/19.
//  Copyright © 2019 Cesar. All rights reserved.
//

import UIKit
import CoreData
import CPAProxy

class ViewController: UIViewController, URLSessionDelegate {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var torWebView: UIWebView!
    
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func connectButtonAction(_ sender: Any) {
        loadTor()
        self.connectButton.isEnabled = false
    }
    
    func setupCompleted(SOCKSHost: String, SOCKSPort: Int) {
        let proxyDict: Dictionary = [kCFStreamPropertySOCKSProxyHost: SOCKSHost,
                                     kCFStreamPropertySOCKSProxyPort: SOCKSPort ] as [CFString : Any]
        
        let configuration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = proxyDict
        let urlSession: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let url: URL = URL(string: "https://check.torproject.org")!
        let dataTask = urlSession.dataTask(with: url){ (data, response, error) in
            if error == nil {
                self.torWebView.load(data!, mimeType: "text/html", textEncodingName: "", baseURL: url)
            } else {
                print("ERROR: \(String(describing: error))")
                self.connectButton.isEnabled = true
            }
            
        }
        dataTask.resume()
    }
    
    func loadTor() {
        
        let cpaProxyBundleURL: URL = Bundle.init(for: CPAProxyManager.self).url(forResource: "CPAProxy", withExtension: "bundle")!
        let cpaProxyBundle: Bundle = Bundle.init(url: cpaProxyBundleURL)!
        
        let torrcPath: String = cpaProxyBundle.path(forResource: "torrc", ofType: nil)!
        let geoipPath: String = cpaProxyBundle.path(forResource: "geoip", ofType: nil)!
        
        let documentsDirectory: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let torDataDir: String = (NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent("tor")?.absoluteString)!
        
        let configuration: CPAConfiguration = CPAConfiguration(torrcPath: torrcPath, geoipPath: geoipPath, torDataDirectoryPath: torDataDir)
        
        let cpaProxyManager: CPAProxyManager = CPAProxyManager(configuration: configuration)
        cpaProxyManager.setup(completion: {socksHost,socksPort,error in
            if(error == nil) {
                self.setupCompleted(SOCKSHost: socksHost!, SOCKSPort: Int(socksPort))
            }else {
                print(error!)
                self.infoLabel.text = error.debugDescription
            }
        }, progress: {progress,summaryString in
            self.infoLabel.text = "Progress: \(progress) \(summaryString!)"
            print(cpaProxyManager.status)
        })
        
    }
    
}

