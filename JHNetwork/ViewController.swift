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
        
        
        test2()
    }
    
    func test2() {
        JHNetwork.shared.baseUrl = url3
        let par: [String: Any]? = [:]
        JHNetwork.shared.autoEncode = true
        JHNetwork.shared.getNoCacheData(url: "s/wd=你好", parameters: par) { (re, er) in
            if er != nil {
                print("error = \(er)")
            }else{
                print("response = \(re)")
            }
        }
    }
    
    func test1() {
        JHNetwork.shared.baseUrl = "http://int.dpool.sina.com.cn"
//        JHNetwork.shared.requestData(methodType: .POST, urlStr: "iplookup/iplookup.php?format=json&ip=218.4.255.255", refreshCache: true, isCache: true, parameters: nil) { (result, error) in
//            print("1 => ",result ?? "result == nil")
//            print("\n")
//            print(error ?? "error == nil")
//        }
        
        JHNetwork.shared.getNoCacheData(url: "iplookup/iplookup.php?format=json&ip=218.4.255.250", refreshCache: false, parameters: nil) { (result, error) in
            print("result = \(result)")
            print("error = \(error)")
        }
    
        
        //
        //        let url3 = "http://ip.taobao.com/service/getIpInfo.php?ip=63.223.108.42"
        //        JHNetwork.shared.postData(url: url2) { (result, error) in
        //            print("2 => ",result ?? "result == nil")
        //            print("\n")
        //            print(error ?? "error == nil")
        //        }
        
        let par:[String : Any] = ["xx":2.22,"name":"wujh","sex":0]
        //        JHNetwork.shared.postData(url: url2, parameters: ["xx":par]) { (js, error) in
        //
        //        }
        
        
        JHNetwork.shared.listenNetworkReachabilityStatus { (status) in
            
        }
        JHNetwork.shared.shoulObtainLocalWhenUnconnected(shouldObtain: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

