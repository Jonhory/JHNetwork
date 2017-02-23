//
//  JHNetwork.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

enum RequestType:Int {
    case GET
    case POST
}

class JHNetwork{
    //MARK:单例
    static let shared = JHNetwork()
    private init() {}
    
    typealias networkResponse = (_ result:AnyObject?,_ error:NSError?) -> ()
    typealias networkJSON = (_ result:JSON?,_ error:NSError?) -> ()
}

extension JHNetwork{
  
    //MARK:GET
    func getData(urlString:String,finished:@escaping networkJSON) {
        getData(urlString: urlString, parameters: nil, finished: finished)
    }
    
    func getData(urlString:String,parameters:[String :AnyObject]?,finished:@escaping networkJSON) {
        getData(urlString: urlString, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    func getData(urlString:String,refreshCache:Bool,parameters:[String :AnyObject]?,finished:@escaping networkJSON) {
        requestData(methodType: .GET, urlStr: urlString, refreshCache: refreshCache, parameters: parameters, finished: finished)
    }
    
    //MARK:POST
    func postData(urlString:String,finished:@escaping networkJSON) {
        postData(urlString: urlString, parameters: nil, finished: finished)
    }
    
    func postData(urlString:String,parameters:[String :AnyObject]?,finished:@escaping networkJSON) {
        postData(urlString: urlString, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    func postData(urlString:String,refreshCache:Bool,parameters:[String :AnyObject]?,finished:@escaping networkJSON) {
        requestData(methodType: .POST, urlStr: urlString, refreshCache: refreshCache, parameters: parameters, finished: finished)
    }
    
    //MARK:请求JSON数据最底层
    func requestData(methodType:RequestType,urlStr:String,refreshCache:Bool,parameters:[String :AnyObject]?,finished:@escaping networkJSON){
        //1.定义请求结果回调闭包
        let resultCallBack = { (response: DataResponse<Any>)in
            if response.result.isSuccess{
                let value = response.result.value as AnyObject?
                finished(JSON(value as Any),nil)
            }else{
                finished(nil,response.result.error as NSError?)
            }
        }
        //2.请求数据
        let httpMethod:HTTPMethod = methodType == .GET ? .get : .post
        request(urlStr,method:httpMethod,parameters:parameters,encoding:URLEncoding.default,headers:nil).responseJSON(completionHandler:resultCallBack)
        
    }
    
}


