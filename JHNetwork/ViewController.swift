//
//  ViewController.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url2 = "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=json&ip=218.4.255.255"
        JHNetwork.shared.requestData(methodType: .GET, urlStr: url2, refreshCache: true, parameters: nil) { (result, error) in
            print("1 => ",result ?? "result == nil")
            print("\n")
            print(error ?? "error == nil")
        }
        
        let url3 = "http://ip.taobao.com/service/getIpInfo.php?ip=63.223.108.42"
        JHNetwork.shared.postData(urlString: url3) { (result, error) in
            print("2 => ",result ?? "result == nil")
            print("\n")
            print(error ?? "error == nil")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

