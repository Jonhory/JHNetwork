//
//  ViewController.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//

import UIKit
import ObjectMapper

class ViewController: UIViewController {

    let url2 = "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=json&ip=218.4.255.255"
    let url3 = "http://www.baidu.com/"
    
    var area: Area? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        test3()
    }
    
    func test5() {
        JHNetwork.shared.clearCaches()
    }
    
    func test4() {
        WLog(JHNetwork.shared.totalCacheSize())
    }
    
    func test3() {
        var params: [String: Any]? = [:]
        params?["haha"] = [1,2,3,4]
        params?["nihao"] = "jjj"
        params?["hehe"] = [:]
        
//        JHNetwork.shared.getCacheForJSON(url: url2, parameters: params) { (js, _) in
//            WLog(js)
//            if js != nil {
//                self.area = Mapper<Area>().map(JSON: (js!.dictionaryObject)!)
////                print("area = \(self.area)")
//                print("js.city = \(js?["city"]["jj"])")
//                
//                
//            }
//        }
        
        JHNetwork.shared.getCacheForJSON(url: url2, parameters: params) { print($0) }
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

