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
    

    
    /// 普通网络回调
    typealias networkResponse = (_ result:Any?,_ error:NSError?) -> ()
    /// JSON数据回调
    typealias networkJSON = (_ result:JSON?,_ error:NSError?) -> ()
    typealias networkListen = (_ status:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
    
    /// 网络基础url
    var baseUrl:String? = nil
    /// 是否自动ecode
    var autoEncode = false
    /// 是否缓存get请求回调
    var cacheGet = true
    /// 是否缓存post请求回调
    var cachePost = true
    /// 取消请求时，是否返回失败回调
    var shouldCallbackOnCancelRequest = false
    /// 请求超时
    var timeout = 15
    /// 网络异常时，是否从本地提取数据
    private var shoulObtainLocalWhenUnconnected = true
    /// 当前网络状态，默认WIFI，开启网络状态监听后有效
    var networkStatus = NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi)
    
    var manager:SessionManager!
    let listen = NetworkReachabilityManager()
    
    
    /// 当检测到网络异常时,是否从本地提取数据,如果是并且缓存post或者缓存get回调，则发起网络状态监听
    ///
    /// - Parameter shouldObtain: 是否从本地提取数据
    func shoulObtainLocalWhenUnconnected(shouldObtain:Bool) {
        shoulObtainLocalWhenUnconnected = shouldObtain
        if shouldObtain && (cacheGet || cachePost) {
            listenNetworkReachabilityStatus {_ in }
        }
    }
}

// MARK: - 公共工具
extension JHNetwork {
    
    /// MD5加密
    ///
    /// - Parameter str: 需要加密的字符串
    /// - Returns: 32位大写加密
    func md5String(str:String) -> String{
        let cStr = str.cString(using: String.Encoding.utf8);
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(cStr!,(CC_LONG)(strlen(cStr!)), buffer)
        let md5String = NSMutableString();
        for i in 0 ..< 16{
            md5String.appendFormat("%02x", buffer[i])
        }
        free(buffer)
        return md5String as String
    }
    
    
    /// 监听网络状态
    ///
    /// - Parameter networkListen: 网络状态回调
    func listenNetworkReachabilityStatus(networkListen:@escaping networkListen) {
        listen?.startListening()
        listen?.listener = { status in
            self.networkStatus = status
            
//            print("*** <<<Network Status Changed>>> ***:\(status)")
//            networkListen(status)
        }
    }
}

// MARK: - 网络请求相关
extension JHNetwork{
  
    //MARK:GET
    func getData(url:String,finished:@escaping networkJSON) {
        getData(url: url, parameters: nil, finished: finished)
    }
    
    func getData(url:String,parameters:[String :Any]?,finished:@escaping networkJSON) {
        getData(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    func getData(url:String,refreshCache:Bool,parameters:[String :Any]?,finished:@escaping networkJSON) {
        requestData(methodType: .GET, urlStr: url, refreshCache: refreshCache, parameters: parameters, finished: finished)
    }
    
    //MARK:POST
    func postData(url:String,finished:@escaping networkJSON) {
        postData(url: url, parameters: nil, finished: finished)
    }
    
    func postData(url:String,parameters:[String :Any]?,finished:@escaping networkJSON) {
        postData(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    func postData(url:String,refreshCache:Bool,parameters:[String :Any]?,finished:@escaping networkJSON) {
        requestData(methodType: .POST, urlStr: url, refreshCache: refreshCache, parameters: parameters, finished: finished)
    }
    
    //MARK:请求JSON数据最底层
    func requestData(methodType:RequestType,urlStr:String,refreshCache:Bool,parameters:[String :Any]?,finished:@escaping networkJSON){
        //1.定义请求结果回调闭包
        let resultCallBack = { (response: DataResponse<Any>)in
            if response.result.isSuccess{
                let value = response.result.value as Any?
                finished(JSON(value as Any),nil)
                self.cacheResponse(response: response.result.value, url: urlStr, parameters: parameters)
            }else{
                finished(nil,response.result.error as NSError?)
            }
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(timeout)
        manager = Alamofire.SessionManager(configuration: config)
        //2.请求数据
        let httpMethod:HTTPMethod = methodType == .GET ? .get : .post
        manager.request(urlStr,method:httpMethod,parameters:parameters,encoding:URLEncoding.default,headers:nil).responseJSON(completionHandler:resultCallBack)
        
    }
    
    /// 将传入的参数字典转成字符串用于显示和判断唯一性，仅对一级字典结构有效
    ///
    /// - Parameters:
    ///   - url: 完整的url
    ///   - params: 参数字典
    /// - Returns: GET形式的字符串
    func generateGETAbsoluteURL(url:String,params:[String:Any]?) -> String{
        var absoluteUrl = ""
        
        if params != nil {
            let par = appendDefaultParameter(params: params)
            for (key,value):(String,Any) in par!{
                if value is String {
                    absoluteUrl = absoluteUrl + "&" + key + "=" + (value as! String)
                }else if value is Int {
                    absoluteUrl = absoluteUrl + "&" + key + "=" + "\(value as! Int)"
                }else if value is Double {
                    absoluteUrl = absoluteUrl + "&" + key + "=" + "\(value as! Double)"
                }
            }
        }
        
        absoluteUrl = url + absoluteUrl
        
        return absoluteUrl
    }
    
    func cacheResponse(response:Any?,url:String,parameters:[String :Any]?) {
        print("response = \(response) \n url = \(url) \n parameters= = \(parameters)")
        print("md5 = \(self.md5String(str: url))")
        
    }
    
    func absoluteUrlWithPath(path:String) -> String {
        return path
    }
    
    func appendDefaultParameter(params:[String:Any]?) -> [String:Any]? {
        var par = params
        par?["version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return par
    }
}




