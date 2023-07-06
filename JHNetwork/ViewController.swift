//
//  ViewController.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    let url2 = "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=json&ip=218.4.255.255"
    let url3 = "https://www.sojson.com"
    
    lazy var respLab: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "准备请求中"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20)
        label.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        label.textAlignment = .center
        return label
    }()
    
    lazy var remarkLab: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "点击屏幕重新发起请求"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
//        JHNetwork.shared.clearCaches()
        let c = JHNetwork.shared.totalCacheSize()
        WLog("缓存大小:\(c)B")
        
        view.addSubview(respLab)
        respLab.center = view.center
        
        view.addSubview(remarkLab)
        remarkLab.center = CGPoint(x: view.center.x, y: view.center.y - 100)
        
        JHNetwork.shared.encodeAble = true
        
        test1()
    }
    
    
    func test1() {
        let url = "http://baike.baidu.com/api/openapi/BaikeLemmaCardApi?scope=103&format=json&appid=379020&bk_key=关键字&bk_length=600"
//        let url2 = "http://api.map.baidu.com/telematics/v3/weather?location=嘉兴&output=json&ak=5slgyqGDENN7Sy7pw29IUvrZ"
        
        JHNetwork.shared.request(methodType: .get,
                                 urlStr: url,
                                 refreshCache: true,
                                 isCache: true,
                                 parameters: nil,
                                 of: DemoResp.self,
                                 codeHandler: false) {[weak self] result, error in
            guard let self = self else { return }
//            WLog("请求✅ \(result) error=\(error)")
            if let result = result {
                if let errno = result.errno {
                    self.respLab.text = "请求完成 ❌ errno:\(errno)"
                } else {
                    self.respLab.text = "请求完成 ✅\n\(result.desc ?? "")"
                }
            } else {
                self.respLab.text = "请求完成 ❌ \(error ?? "")"
            }
        }
//        JHNetwork.shared.requestCodable(methodType: .get, urlStr: url, refreshCache: false, isCache: false, parameters: nil, of: DemoResp.self, finished: { result, error in
//            WLog("请求✅ \(result)")
//        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        test1()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

