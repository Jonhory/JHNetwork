//
//  JHNetwork.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//

import UIKit
import Alamofire

class JHNetwork{
    //MARK:单例
    static let shared = JHNetwork()
    private init() {}
    
    var isDebug = false
    var JHResponseFail: ((_ error: Error) -> Void)? = nil
    
}

extension JHNetwork{
    /// 发送POST请求
//    func postRequest(urlString : String, params : [String : AnyObject], success : (responseObject : [String : AnyObject])->(), failture : (error : NSError)->()) {
//        
//        Alamofire.request(.POST,urlString,parameters: params).responseJSON
//            {response in
//                switch response.result {
//                case.Success:
//                    if let value = response.result.value as? [String : AnyObject] {
//                        success(responseObject: value)
//                    }
//                case .Failure(let error):
//                    failture(error: error)
//                }
//        }
//    }
//    
//    /// 发送GET请求
//    func getRequest(urlString : String, params : [String : AnyObject], success : (responseObject : [String : AnyObject])->(), failture : (error : NSError)->()) {
//        
//        Alamofire.request(.GET,urlString,parameters: params).responseJSON
//            {response in
//                switch response.result {
//                case.Success:
//                    if let value = response.result.value as? [String : AnyObject] {
//                        success(responseObject: value)
//                    }
//                case .Failure(let error):
//                    failture(error: error)
//                }
//        }
//    }
    func postWithUrl(url :String) -> Void {
        let urlRequest = URLRequest(url: URL(string: url)!)
        let urlString = urlRequest.url?.absoluteString
        
    }
}
