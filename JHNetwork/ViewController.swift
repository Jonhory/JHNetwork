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

    let url2 = "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=json&ip=218.4.255.255"
    let url3 = "http://www.baidu.com/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        JHNetwork.shared.shoulObtainLocalWhenUnconnected(shouldObtain: true)
        test1()
    }
    
    func test5() {
        JHNetwork.shared.clearCaches()
    }
    
    func test4() {
        WLog(JHNetwork.shared.totalCacheSize())
    }
    
    func test3() {
        JHNetwork.shared.getCacheForJSON(url: url2, parameters: nil) { (js, _) in
            WLog(js)
        }
    }
    
    func test2() {
        JHNetwork.shared.baseUrl = url3
        let par: [String: Any]? = [:]
        JHNetwork.shared.encodeAble = true
        JHNetwork.shared.getNoCacheForJSON(url: "s/wd=你好", parameters: par) { (re, er) in
            if er != nil {
                print("error = \(er)")
            }else{
                print("response = \(re)")
            }
        }
    }
    
    func test1() {
        JHNetwork.shared.baseUrl = "http://int.dpool.sina.com.cn"
        
        JHNetwork.shared.getForJSON(url: url2, refreshCache: true, parameters: nil) { (result, error) in
        }
        
        JHNetwork.shared.getForJSON(url: url2, refreshCache: true, parameters: ["name":"jj"]) { (result, error) in
        }
        
        JHNetwork.shared.shoulObtainLocalWhenUnconnected(shouldObtain: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

