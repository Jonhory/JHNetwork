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
        
        JHNetwork.shared.getWithUrl(url: "http://www.weather.com.cn/data/sk/101190408.html", success: { (DefaultDataResponse) in
            print(DefaultDataResponse)
            if let value = DefaultDataResponse.result.value {
                let weatherinfo = JSON(value)
                if let info = weatherinfo["weatherinfo"].dictionary{
                    for (key,value):(String,JSON) in info {
                        print(key , "+ : +" ,value)
                    }
                }

            }
        }) { (error) in
            
        }
        
        /* 基础的请求 及JSON数据解析 */
        Alamofire.request("https://api.500px.com/v1/photos").responseJSON { (DataResponse) in
            
            if let Json = DataResponse.result.value{
                print("Json:\(Json) ")
                // NSData->NSDictonary
                let dic = try? JSONSerialization.jsonObject(with: DataResponse.data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
                let status = dic? ["status"]
                print("status is \(status)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

