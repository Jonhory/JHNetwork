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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        test3()
    }
    
    func test3() {
        let js = JHNetwork.shared.getCacheResponseWithURL(url: url2, parameters: nil)
        print("js = \(js)")
    }
    
    func test2() {
        JHNetwork.shared.baseUrl = "http://www.baidu.com/"
        let url = JHNetwork.shared.absoluteUrlWithPath(path: "http://www.baidu.com/nihao")
        print(url)
    }
    
    func test1() {
        
        JHNetwork.shared.requestData(methodType: .POST, urlStr: url2, refreshCache: true, parameters: nil) { (result, error) in
            print("1 => ",result ?? "result == nil")
            print("\n")
            print(error ?? "error == nil")
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
        
        let ss = JHNetwork.shared.generateGETAbsoluteURL(url: url2, params: par)
        print(ss)
        
        JHNetwork.shared.listenNetworkReachabilityStatus { (status) in
            
        }
        JHNetwork.shared.shoulObtainLocalWhenUnconnected(shouldObtain: false)
        
        
        let baseUrl:String? = "/xxxx"
        var absolute = baseUrl!
        absolute.remove(at: baseUrl!.index(baseUrl!.startIndex, offsetBy: 0))
        print("bababab",absolute)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

