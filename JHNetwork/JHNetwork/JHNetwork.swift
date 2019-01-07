//
//  JHNetwork.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//  

import UIKit
import Alamofire
import SwiftyJSON

//MARK:公共方法
/// 自定义Log
///
/// - Parameters:
///   - messsage: 正常输出内容
///   - file: 文件名
///   - funcName: 方法名
///   - lineNum: 行数
func WLog<T>(_ messsage: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("\(fileName):(\(lineNum))======>>>>>>\n\(messsage)")
    #endif
}

/// MD5加密
///
/// - Parameter str: 需要加密的字符串
/// - Returns: 32位大写加密
func md5(_ str: String) -> String {
    let cStr = str.cString(using: String.Encoding.utf8)
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    CC_MD5(cStr!,(CC_LONG)(strlen(cStr!)), buffer)
    let md5String = NSMutableString()
    for i in 0 ..< 16 {
        md5String.appendFormat("%02x", buffer[i])
    }
    free(buffer)
    return md5String as String
}

class JHNetwork {
    //MARK:单例
    static let shared = JHNetwork()
    private init() {}
    
    /// 普通网络回调
    typealias networkResponse = (_ result:Any?,_ error:NSError?) -> ()
    /// JSON数据回调
    typealias networkJSON = (_ result:JSON?,_ error:NSError?) -> ()
    /// 网络状态监听回调
    typealias networkListen = (_ status:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
    
    /// 网络基础url
    var baseUrl:String? = nil
    /// 请求超时
    var timeout = 20
    ///配置公共请求头
    var httpHeader:HTTPHeaders? = nil
    /// 是否自动ecode
    var encodeAble = false
    /// 设置是否打印log信息
    var isDebug = true
    /// 网络异常时，是否从本地提取数据
    var shoulObtainLocalWhenUnconnected = true
    /// 当前网络状态，默认WIFI，开启网络状态监听后有效
    var networkStatus = NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi)
    
    var manager:SessionManager!
    let listen = NetworkReachabilityManager()
    
    /// 当检测到网络异常时,是否从本地提取数据,如果是，则发起网络状态监听
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
    /// 监听网络状态
    ///
    /// - Parameter networkListen: 网络状态回调
    func listenNetworkReachabilityStatus(networkListen:@escaping networkListen) {
        listen?.startListening()
        listen?.listener = { status in
            self.networkStatus = status
            if self.isDebug {
                WLog("*** <<<Network Status Changed>>> ***:\(status)")
            }
            networkListen(status)
        }
        if listen?.isReachable == false {
            networkStatus = .notReachable
            networkListen(networkStatus)
        }
    }
}

// MARK: - 网络请求相关
extension JHNetwork {
    
    //MARK: - 缓存相关
    @discardableResult
    func getCacheForJSON(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return getForJSON(url: url, refreshCache: false, parameters: parameters) { (js, error) in
            finished(js, nil)
        }
    }
    
    //MARK:缓存GET
    @discardableResult
    func getForJSON(url: String, finished: @escaping networkJSON) -> Cancellable? {
        return getForJSON(url: url, parameters: nil, finished: finished)
    }
    
    @discardableResult
    func getForJSON(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return getForJSON(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    @discardableResult
    func getForJSON(url: String, refreshCache: Bool, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return requestJSON(methodType: .get, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, finished: finished)
    }
    
    //MARK:不缓存GET
    @discardableResult
    func getNoCacheForJSON(url: String, finished: @escaping networkJSON) -> Cancellable? {
        return getNoCacheForJSON(url: url, parameters: nil, finished: finished)
    }
    
    @discardableResult
    func getNoCacheForJSON(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return getNoCacheForJSON(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    @discardableResult
    func getNoCacheForJSON(url: String, refreshCache: Bool, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return requestJSON(methodType: .get, urlStr: url, refreshCache: refreshCache, isCache: false, parameters: parameters, finished: finished)
    }
    
    //MARK:缓存POST
    @discardableResult
    func postForJSON(url: String, finished: @escaping networkJSON) -> Cancellable? {
        return postForJSON(url: url, parameters: nil, finished: finished)
    }
    
    @discardableResult
    func postForJSON(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return postForJSON(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    @discardableResult
    func postForJSON(url: String, refreshCache: Bool, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return requestJSON(methodType: .post, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, finished: finished)
    }
    
    //MARK:不缓存POST
    @discardableResult
    func postNoCacheForJSON(url: String, finished: @escaping networkJSON) -> Cancellable? {
        return postNoCacheForJSON(url: url, parameters: nil, finished: finished)
    }
    
    @discardableResult
    func postNoCacheForJSON(url: String, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return postNoCacheForJSON(url: url, refreshCache: true, parameters: parameters, finished: finished)
    }
    
    @discardableResult
    func postNoCacheForJSON(url: String, refreshCache: Bool, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        return requestJSON(methodType: .post, urlStr: url, refreshCache: refreshCache, isCache: false, parameters: parameters, finished: finished)
    }
    
    //MARK:请求JSON数据最底层
    
    /// 请求JSON数据最底层
    ///
    /// - Parameters:
    ///   - methodType: GET/POST
    ///   - urlStr: 接口
    ///   - refreshCache: 是否刷新缓存,如果为false则返回缓存
    ///   - isCache: 是否缓存
    ///   - parameters: 参数字典
    ///   - finished: 回调
    @discardableResult
    func requestJSON(methodType: HTTPMethod, urlStr: String, refreshCache: Bool, isCache:Bool, parameters: [String :Any]?, finished: @escaping networkJSON) -> Cancellable? {
        
        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return nil
        }
        let absolute = ready.1
        let param: [String: Any] = appendDefaultParameter(params: parameters) ?? [:]
        if isDebug {
            WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 params ==>> \(String(describing: param)) \n开始请求 🌏 Method: \(methodType.rawValue)")
        }
        //开始业务判断
        if isCache {
            if shoulObtainLocalWhenUnconnected {
                if networkStatus == NetworkReachabilityManager.NetworkReachabilityStatus.unknown || networkStatus == NetworkReachabilityManager.NetworkReachabilityStatus.notReachable {
                    let js = getCacheResponse(url: urlStr, parameters: parameters)
                    if js != nil {
                        if isDebug {
                            WLog("🇨🇳因为无网络连接而读取缓存")
                        }
                        networkLogSuccess(json: js, url: urlStr, params: parameters)
                        finished(js, nil)
                        return nil
                    }
                }
            }
            //如果不刷新缓存，如果已存在缓存，则返回缓存，否则请求网络，但是不缓存数据
            if !refreshCache {
                let js = getCacheResponse(url: urlStr, parameters: parameters)
                if js != nil {
                    if isDebug {
                        WLog("🇨🇳因为不刷新缓存而读取缓存")
                    }
                    networkLogSuccess(json: js, url: urlStr, params: parameters)
                    finished(js, nil)
                    return nil
                }
            }
        }
        
        //定义请求结果回调闭包
        let resultCallBack = { (response: DataResponse<Any>) in
            if response.result.isSuccess {
                let value = response.result.value as Any?
                let js = JSON(value as Any)
                // 如果刷新缓存并且缓存
                if refreshCache && isCache {
                    self.cacheResponse(response: js, url: urlStr, parameters: parameters)
                }
                self.networkLogSuccess(json: js, url: urlStr, params: parameters)
                finished(js, nil)
            } else {
                let error = response.result.error as NSError?
                if error != nil && error!.code < 0 && isCache {
                    let js = self.getCacheResponse(url: urlStr, parameters: parameters)
                    if js != nil {
                        if self.isDebug {
                            WLog("🇨🇳因为\(String(describing: error))而读取缓存")
                        }
                        self.networkLogSuccess(json: js, url: urlStr, params: parameters)
                        finished(js, nil)
                    } else {
                        self.networkLogFail(error: error, url: urlStr, params: parameters)
                        finished(nil, error)
                    }
                } else {
                    self.networkLogFail(error: error, url: urlStr, params: parameters)
                    finished(nil, error)
                }
            }
        }
        
        //正式发起网络请求
        let encoding: ParameterEncoding = JSONEncoding.default
        let req = manager.request(absolute!, method: methodType, parameters: param, encoding: encoding, headers: httpHeader)
        return req.responseJSON(completionHandler: resultCallBack)
        
    }
    
    // MARK: 上传图片数组, 图片数组的 key 是 images 使用multipart/form-data格式提交图片
    
    /// 上传图片数组
    ///
    /// - Parameters:
    ///   - par: key是 images ，value是 UIImage
    ///   - urlStr: 上传路径
    ///   - finished: 回调
    func upload(par: [String: Any] , urlStr: String, finished: @escaping networkJSON) {
        
        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return
        }
        let absolute = ready.1
        
        let param = appendDefaultParameter(params: par)
        
        let headers = ["content-type" : "multipart/form-data"]
        
        manager.upload(multipartFormData: { (formData) in
            
            for (key, value) in param! {
                if key == "images" {
                    if let images = value as? [UIImage] {
                        for i in 0..<images.count {
                            let image = images[i]
                            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                                formData.append(imageData, withName: "iOSImage\(i)", fileName: "image\(i).png", mimeType: "image/png")
                            }
                        }
                    }
                } else {
                    if let va = value as? String {
                        if let vaData = va.data(using: .utf8) {
                            formData.append(vaData, withName: key)
                        }
                    }
                }
            }
            
        }, to: absolute!, headers: headers) { (encodingResult) in
            
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON(completionHandler: { (resp) in
                    if resp.result.isSuccess {
                        let value = resp.result.value as Any?
                        let js = JSON(value as Any)
                        self.networkLogSuccess(json: js, url: urlStr, params: nil)
                        finished(js, nil)
                    } else {
                        let error = resp.result.error as NSError?
                        self.networkLogFail(error: error, url: urlStr, params: nil)
                        finished(nil, error)
                    }
                })
                break
            case .failure(let error):
                let err = error as NSError?
                finished(nil, err)
                break
            }
        }
        
    }
    
    /// 获取网络数据缓存字节数
    ///
    /// - Returns: 网络数据缓存字节数
    func totalCacheSize() -> Double {
        let path = cachePath()
        var isDir: ObjCBool = false
        var total: Double = 0
        
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        if isDir.boolValue {
            do {
                let array = try FileManager.default.contentsOfDirectory(atPath: path)
                for subPath in array {
                    let subPath = path + "/" + subPath
                    do {
                        let dict: NSDictionary = try FileManager.default.attributesOfItem(atPath: subPath) as NSDictionary
                        total += Double(dict.fileSize())
                    } catch  {
                        if isDebug {
                            WLog("‼️失败==\(error)")
                        }
                    }
                    
                }
            } catch  {
                if isDebug {
                    WLog("‼️失败==\(error)")
                }
            }
        }
        return total
    }
    
    
    /// 清除网络数据缓存
    func clearCaches() {
        DispatchQueue.global().async {
            let path = self.cachePath()
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            if isDir.boolValue {
                do {
                    try FileManager.default.removeItem(atPath: path)
                    if self.isDebug {
                        WLog("清除网络数据缓存成功🍎")
                    }
                } catch  {
                    if self.isDebug {
                        WLog("清除网络数据缓存失败‼️ \(error)")
                    }
                }
                
            }
        }
    }
    
    //MARK: 私有方法
    
    // MARK: 准备工作
    private func readySendRequest(urlStr: String) -> (Bool, String?) {
        var absolute: String? = nil
        absolute = absoluteUrl(path: urlStr)
        if encodeAble {
            absolute = absolute?.urlEncode
            if isDebug {
                WLog("Encode URL ===>>>>\(absolute.orNil)")
            }
        }
        
        let URL: NSURL? = NSURL(string: absolute!)
        if URL == nil {
            if isDebug {
                WLog("URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL, absolute = \(absolute.orNil)")
            }
            return (false, nil)
        }
        
        if manager == nil {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = TimeInterval(timeout)
            manager = Alamofire.SessionManager(configuration: config)
        }
        
        return (true, absolute!)
    }
    
    /// 成功的日志输出
    ///
    /// - Parameters:
    ///   - json: 成功的回调
    ///   - url: 接口
    ///   - params: 参数
    private func networkLogSuccess(json: JSON?, url: String, params: [String:Any]?) {
        if isDebug {
            let absolute = absoluteUrl(path: url)
            let param: [String: Any] = appendDefaultParameter(params: params) ?? [:]
            WLog("请求成功🍎, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json ?? JSON()))")
        }
    }
    
    
    /// 失败的日志输出
    ///
    /// - Parameters:
    ///   - error: 失败信息
    ///   - url: 接口信息
    ///   - params: 参数字典
    private func networkLogFail(error: NSError?, url: String, params: [String:Any]?) {
        if isDebug {
            let absolute = absoluteUrl(path: url)
            let param: [String: Any] = appendDefaultParameter(params: params) ?? [:]
            if error?.code == NSURLErrorCancelled {
                WLog("请求被取消🏠, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \n错误信息❌ ==>> \(String(describing: error))")
            } else {
                WLog("请求错误, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \n错误信息❌ ==>> \(String(describing: error))")
            }
        }
    }
    
    /// 将传入的参数字典转成字符串用于显示和判断唯一性，仅对一级字典结构有效
    ///
    /// - Parameters:
    ///   - url: 完整的url
    ///   - params: 参数字典
    /// - Returns: GET形式的字符串
    private func generateGETAbsoluteURL(url: String, params: [String:Any]?) -> String {
        var absoluteUrl = ""
        
        if params != nil {
            let par = appendDefaultParameter(params: params)
            for (key,value):(String,Any) in par! {
                if value is [Any] || value is [AnyHashable: Any] || value is Set<AnyHashable> {
                    continue
                } else {
                    absoluteUrl = "\(absoluteUrl)&\(key)=\(value)"
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
    private func cacheResponse(response: JSON?, url: String, parameters: [String :Any]?) {
        if response != nil {
            let directoryPath = cachePath()
            if !FileManager.default.fileExists(atPath: directoryPath) {
                do {
                    try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    if isDebug {
                        WLog("创建文件夹失败 ‼️ \(error)")
                    }
                    return
                }
            }
            let absolute = absoluteUrl(path: url)
            let absoluteGet = generateGETAbsoluteURL(url: absolute, params: parameters)
            let key = md5(absoluteGet)
            let path = directoryPath.appending("/\(key)")
            var data:Data? = nil
            do {
                data = try JSONSerialization.data(withJSONObject: response?.dictionaryObject ?? [:], options: .prettyPrinted)
            } catch  {
                if isDebug {
                    WLog("‼️ \(error)")
                }
            }
            if data != nil {
                FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
                if isDebug {
                    WLog("保存网络数据成功 🌏 \(absoluteGet)")
                }
            }
            
        }
    }

    
    /// 获取缓存的JSON数据
    ///
    /// - Parameters:
    ///   - url: 外部接口
    ///   - parameters: 参数字典
    /// - Returns: 缓存的JSON数据
    private func getCacheResponse(url: String, parameters: [String :Any]?) -> JSON? {
        var json:JSON? = nil
        let directoryPath = cachePath()
        let absolute = absoluteUrl(path: url)
        let absoluteGet = generateGETAbsoluteURL(url: absolute, params: parameters)
        let key = md5(absoluteGet)
        let path = directoryPath.appending("/\(key)")
        let data = FileManager.default.contents(atPath: path)
        if data != nil {
            json = JSON(data!)
            if isDebug {
                WLog("读取缓存的数据 🌏 \(absoluteGet)")
            }
        }
        
        return json
    }
    
    /// 拼接基础路径和接口路径
    ///
    /// - Parameter path: 接口路径
    /// - Returns: 完整的接口url
    private func absoluteUrl(path: String?) -> String {
        if path == nil || path?.count == 0 {
            if baseUrl != nil {
                return baseUrl!
            }
            return ""
        }
        if baseUrl == nil || baseUrl?.count == 0 {
            return path!
        }
        var absoluteUrl = path!
        if !path!.hasPrefix("http://") && !path!.hasPrefix("https://") {
            if baseUrl!.hasSuffix("/") {
                if path!.hasPrefix("/") {
                    var mutablePath = path!
                    mutablePath.remove(at: mutablePath.index(mutablePath.startIndex, offsetBy: 0))
                    absoluteUrl = baseUrl! + mutablePath
                } else {
                    absoluteUrl = baseUrl! + path!
                }
            } else {
                if path!.hasPrefix("/") {
                    absoluteUrl = baseUrl! + path!
                } else {
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
    private func appendDefaultParameter(params: [String:Any]?) -> [String:Any]? {
        var par = params
        par?["version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return par
    }
    
    
    /// 获取缓存的文件夹路径
    ///
    /// - Returns: 文件夹路径
    private func cachePath() -> String {
        return NSHomeDirectory().appending("/Library/Caches/JHNetworkCaches")
    }
}

extension String {
    // url encode
    var urlEncode:String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    // url decode
    var urlDecode :String? {
        return self.removingPercentEncoding
    }
}

protocol Cancellable {
    func cancel()
}

extension Request: Cancellable {}

extension Optional {
    var orNil : String {
        if self == nil {
            return ""
        }
        if "\(Wrapped.self)" == "String" {
            return "\(self!)"
        }
        return "\(self!)"
    }
}
