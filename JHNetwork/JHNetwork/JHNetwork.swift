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
    /// 请求超时
    var timeout = 15
    ///配置公共请求头
    var httpHeader:HTTPHeaders? = nil
    /// 是否自动ecode
    var autoEncode = false
    /// 取消请求时，是否返回失败回调
    var shouldCallbackOnCancelRequest = false
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
        if shouldObtain {
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
    func getData(url: String, finished: @escaping networkJSON) {
        getData(url: url, parameters: nil, finished: finished)
    }
    
    func getData(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) {
        getData(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    func getData(url: String, refreshCache: Bool, parameters: [String :Any]?, finished: @escaping networkJSON) {
        requestData(methodType: .GET, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, finished: finished)
    }
    
    //MARK:POST
    func postData(url: String, finished: @escaping networkJSON) {
        postData(url: url, parameters: nil, finished: finished)
    }
    
    func postData(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) {
        postData(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    func postData(url: String, refreshCache: Bool, parameters: [String :Any]?, finished: @escaping networkJSON) {
        requestData(methodType: .POST, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, finished: finished)
    }
    
    //MARK:请求JSON数据最底层
    func requestData(methodType: RequestType, urlStr: String, refreshCache: Bool, isCache:Bool, parameters: [String :Any]?, finished: @escaping networkJSON){
        //1.定义请求结果回调闭包
        let resultCallBack = { (response: DataResponse<Any>)in
            if response.result.isSuccess{
                let value = response.result.value as Any?
                let js = JSON(value as Any)
                finished(js, nil)
                self.cacheResponse(response: js, url: urlStr, parameters: parameters)
            }else{
                finished(nil, response.result.error as NSError?)
            }
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(timeout)
        manager = Alamofire.SessionManager(configuration: config)
        //2.请求数据
        let httpMethod:HTTPMethod = methodType == .GET ? .get : .post
        manager.request(urlStr, method: httpMethod, parameters: parameters, encoding: URLEncoding.default, headers: httpHeader).responseJSON(completionHandler: resultCallBack)
        
    }
    
    /// 将传入的参数字典转成字符串用于显示和判断唯一性，仅对一级字典结构有效
    ///
    /// - Parameters:
    ///   - url: 完整的url
    ///   - params: 参数字典
    /// - Returns: GET形式的字符串
    func generateGETAbsoluteURL(url: String, params: [String:Any]?) -> String{
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
    
    
    /// 保存网络回调数据
    ///
    /// - Parameters:
    ///   - response: 网络回调JSON数据
    ///   - url: 外部传入的接口
    ///   - parameters: 外部传入的参数
    func cacheResponse(response: JSON?, url: String, parameters: [String :Any]?) {
        if response != nil {
            let directoryPath = cachePath()
            if !FileManager.default.fileExists(atPath: directoryPath) {
                do {
                    try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("创建文件夹失败 error = ",error)
                    return
                }
            }
            let absolute = absoluteUrlWithPath(path: url)
            let absoluteGet = generateGETAbsoluteURL(url: absolute, params: parameters)
            let key = md5String(str: absoluteGet)
            let path = directoryPath.appending("/\(key)")
            var data:Data? = nil
            do {
                data = try JSONSerialization.data(withJSONObject: response?.dictionaryObject ?? [:], options: .prettyPrinted)
            } catch  {
                print("Data error = \(error)")
            }
            if data != nil {
                FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
                print("保存网络数据成功 path = \(path), \n url = \(absoluteGet)")
            }
            
        }
    }

    
    /// 获取缓存的JSON数据
    ///
    /// - Parameters:
    ///   - url: 外部接口
    ///   - parameters: 参数字典
    /// - Returns: 缓存的JSON数据
    func getCacheResponseWithURL(url: String, parameters: [String :Any]?) -> JSON? {
        var json:JSON? = nil
        let directoryPath = cachePath()
        let absolute = absoluteUrlWithPath(path: url)
        let absoluteGet = generateGETAbsoluteURL(url: absolute, params: parameters)
        let key = md5String(str: absoluteGet)
        let path = directoryPath.appending("/\(key)")
        let data = FileManager.default.contents(atPath: path)
        if data != nil {
            json = JSON(data!)
            print("读取缓存的数据 URL = \(url)")
        }
        
        return json
    }
    
    /// 拼接基础路径和接口路径
    ///
    /// - Parameter path: 接口路径
    /// - Returns: 完整的接口url
    func absoluteUrlWithPath(path: String?) -> String {
        if path == nil || path?.characters.count == 0 {
            return ""
        }
        if baseUrl == nil || baseUrl?.characters.count == 0 {
            return path!
        }
        var absoluteUrl = path!
        if !path!.hasPrefix("http://") && !path!.hasPrefix("https://"){
            if baseUrl!.hasSuffix("/") {
                if path!.hasPrefix("/") {
                    var mutablePath = path!
                    mutablePath.remove(at: mutablePath.index(mutablePath.startIndex, offsetBy: 0))
                    absoluteUrl = baseUrl! + mutablePath
                }else{
                    absoluteUrl = baseUrl! + path!
                }
            }else{
                if path!.hasPrefix("/") {
                    absoluteUrl = baseUrl! + path!
                }else{
                    absoluteUrl = baseUrl! + "/" + path!
                }
            }
        }
        return absoluteUrl
    }
    
    
    /// 参数字典增加默认key／value
    ///
    /// - Parameter params: 外部传入的参数字典
    /// - Returns: 添加默认key／value的字典
    func appendDefaultParameter(params: [String:Any]?) -> [String:Any]? {
        var par = params
        par?["version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return par
    }
    
    
    /// 获取缓存的文件夹路径
    ///
    /// - Returns: 文件夹路径
    private func cachePath() -> String{
        return NSHomeDirectory().appending("/Library/Caches/JHNetworkCaches")
    }
}




