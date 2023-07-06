//
//  JHNetwork.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//  

import UIKit
import Alamofire

private let dateFormatter = DateFormatter()

typealias BaseResp = BaseRespCodable & Decodable & Encodable

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
    print("\(fileName):(\(lineNum)) \(Date().jh_getDateStr()) \(messsage)")
    #endif
}

extension String {
    
    var sha256: String {
        let utf8 = cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count:  Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format:"%02x", $1) }
    }
}

extension Date {
    
    func jh_getDateStr() -> String {
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        return dateFormatter.string(from: self)
    }
}

protocol BaseRespCodable {
    var code: Int? { get set}
    var message: String? {get set}
}

class JHNetwork {
    //MARK:单例
    static let shared = JHNetwork()
    private init() {}
    
    /// 普通网络回调
//    typealias networkResponse = (_ result:Any?,_ error: AFError?) -> ()
    /// JSON数据回调
    typealias networkJSON<T: BaseResp> = (_ result:T?,_ error: String?) -> ()
    typealias networkCodable<T: Codable> = (_ result:T?,_ error: String?) -> ()
    
    /// 网络状态监听回调
    typealias networkListen = (_ status:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
    
    /// 网络基础url
    var baseUrl:String? = nil
    /// 请求超时
    var timeout = 20
    ///配置公共请求头
    var httpHeader: HTTPHeaders? = nil
    /// 是否自动ecode
    var encodeAble = false
    /// 设置是否打印log信息
    var isDebug = true
    /// 网络异常时，是否从本地提取数据
    var shoulObtainLocalWhenUnconnected = true
    /// 当前网络状态，默认WIFI，开启网络状态监听后有效
    var networkStatus = NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi)
    
    var manager: Session?
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
        listen?.startListening(onUpdatePerforming: { status in
            self.networkStatus = status
            if self.isDebug {
                WLog("*** <<<Network Status Changed>>> ***:\(status)")
            }
            networkListen(status)
        })
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
    func getCacheForJSON<T: BaseResp>(url: String, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return getForJSON(url: url, refreshCache: false, parameters: parameters, remark: remark, of: type) { (js, error) in
            finished(js, nil)
        }
    }

    //MARK:缓存GET
    @discardableResult
    func getForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return getForJSON(url: url, parameters: nil, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getForJSON<T: BaseResp>(url: String, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return getForJSON(url: url, refreshCache: true, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getForJSON<T: BaseResp>(url: String, refreshCache: Bool, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return request(methodType: .get, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    //MARK:不缓存GET
    @discardableResult
    func getNoCacheForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return getNoCacheForJSON(url: url, parameters: nil, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getNoCacheForJSON<T: BaseResp>(url: String, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return getNoCacheForJSON(url: url, refreshCache: true, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getNoCacheForJSON<T: BaseResp>(url: String, refreshCache: Bool, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return request(methodType: .get, urlStr: url, refreshCache: refreshCache, isCache: false, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    //MARK:缓存POST
    @discardableResult
    func postForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return postForJSON(url: url, parameters: nil, of: type, finished: finished)
    }

    @discardableResult
    func postForJSON<T: BaseResp>(url: String, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return postForJSON(url: url, refreshCache: true, parameters: parameters, of: type, finished: finished)
    }

    @discardableResult
    func postForJSON<T: BaseResp>(url: String, refreshCache: Bool, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return request(methodType: .post, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, of: type, finished: finished)
    }

    //MARK:不缓存POST
    @discardableResult
    func postNoCacheForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return postNoCacheForJSON(url: url, parameters: nil, of: type, finished: finished)
    }

    @discardableResult
    func postNoCacheForJSON<T: Codable>(url: String, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return postNoCacheForJSON(url: url, refreshCache: true, parameters: parameters,  of: type, finished: finished)
    }

    @discardableResult
    func postNoCacheForJSON<T: BaseResp>(url: String, refreshCache: Bool, parameters: [String :Any]?, remark: String? = nil, of type: T.Type, finished: @escaping networkJSON<T>) -> DataRequest? {
        return request(methodType: .post, urlStr: url, refreshCache: refreshCache, isCache: false, parameters: parameters, of: type, finished: finished)
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
    ///   - of type: 解析对应的模型类
    ///   - codeHandler: 判断 code ，默认true
    ///   - finished: 回调
    @discardableResult
    func request<T: BaseResp>(
        methodType: HTTPMethod,
        urlStr: String,
        refreshCache: Bool,
        isCache:Bool,
        parameters: [String :Any]?,
        remark: String? = nil,
        of type: T.Type,
        codeHandler: Bool = true,
        finished: @escaping networkJSON<T>
    ) -> DataRequest? {
        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return nil
        }
        let absolute = ready.1
        let param: [String: Any]? = appendDefaultParameter(params: parameters)
        if isDebug {
            if remark.orNil.isEmpty {
                WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 params ==>> \(String(describing: param)) \n开始请求 🌏 Method: \(methodType.rawValue)")
            } else {
                WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 \(remark.orNil) Method: \(methodType.rawValue)\n开始请求 🌏 params ==>> \(String(describing: param))")
            }
        }
        
        if isCache {
            if shoulObtainLocalWhenUnconnected {
                if networkStatus == NetworkReachabilityManager.NetworkReachabilityStatus.unknown || networkStatus == NetworkReachabilityManager.NetworkReachabilityStatus.notReachable {
                    if let js = getCacheResponse(url: urlStr, of: type, parameters: parameters) {
                        if isDebug {
                            WLog("🇨🇳因为无网络连接而读取缓存")
                        }
                        networkLogSuccess(json: js, url: urlStr, params: parameters, remark: remark)
                        finished(js, nil)
                        return nil
                    }
                }
            }
            //如果不刷新缓存，如果已存在缓存，则返回缓存，否则请求网络，但是不缓存数据
            if !refreshCache, let js = getCacheResponse(url: urlStr, of: type, parameters: parameters) {
                if isDebug {
                    WLog("🇨🇳因为不刷新缓存而读取缓存")
                }
                networkLogSuccess(json: js, url: urlStr, params: parameters, remark: remark)
                finished(js, nil)
                return nil
            }
        }
        
        let encoding: ParameterEncoding = JSONEncoding.default
        
        let req = manager?.request(absolute!,
                                  method: methodType,
                                  parameters: param,
                                  encoding: encoding,
                                  headers: httpHeader)
        
        return req?.responseDecodable(of: type, completionHandler: {[weak self] resp in
            guard let self = self else { return }
            
            if let error :AFError = resp.error {
                if let code = error.responseCode, code < 0 && isCache, let js = getCacheResponse(url: urlStr, of: type, parameters: parameters) {
                    if self.isDebug {
                        WLog("🇨🇳因为\(error.localizedDescription)而读取缓存")
                    }
                    self.networkLogSuccess(json: js, url: urlStr, params: param, remark: remark)
                    finished(js, nil)
                    return
                }
                self.networkLogFail(error: error, url: urlStr, params: param, remark: remark)
                finished(nil, error.localizedDescription)
                
            } else {
                guard let data = resp.value else {
                    if isCache, let js = getCacheResponse(url: urlStr, of: type, parameters: param) {
                        if self.isDebug {
                            WLog("🇨🇳因为接口返回异常或解析\(type)异常而读取缓存 description:\(resp.description)")
                        }
                        self.networkLogSuccess(json: js, url: urlStr, params: param, remark: remark)
                        finished(js, nil)
                        return
                    }
                    return
                }
                
                // 如果有需要，可以使用 code 进行全局判断
                if codeHandler && data.code != 200 && data.code != 1 {
                    if isCache, let js = getCacheResponse(url: urlStr, of: type, parameters: parameters) {
                        if self.isDebug {
                            WLog("🇨🇳因为接口返回结果 code=\(data.code ?? -1) msg=\(data.message ?? "") 异常而读取缓存")
                        }
                        self.networkLogSuccess(json: js, url: urlStr, params: param, remark: remark)
                        finished(js, nil)
                        return
                    }
                    finished(nil, data.message ?? "")
                    return
                }
                // 符合期望 成功的请求
                // 如果刷新缓存并且缓存
                if refreshCache && isCache {
                    self.cacheResponse(response: data, url: urlStr, parameters: param)
                }
                self.networkLogSuccess(json: data, url: urlStr, params: param, remark: remark)
                finished(data, nil)
            }
        })
    }
    
    /// 请求JSON数据最底层
    ///
    /// - Parameters:
    ///   - methodType: GET/POST
    ///   - urlStr: 接口
    ///   - of type: 解析对应的模型类
    ///   - parameters: 参数字典
    ///   - finished: 回调
    @discardableResult
    func requestCodable<T: Codable>(
        methodType: HTTPMethod,
        urlStr: String,
        parameters: [String :Any]?,
        remark: String? = nil,
        of type: T.Type,
        finished: @escaping networkCodable<T>
    ) -> DataRequest? {
        
        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return nil
        }
        let absolute = ready.1
        let param: [String: Any]? = appendDefaultParameter(params: parameters)
        if isDebug {
            if remark.orNil.isEmpty {
                WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 params ==>> \(String(describing: param)) \n开始请求 🌏 Method: \(methodType.rawValue)")
            } else {
                WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 \(remark.orNil) Method: \(methodType.rawValue)\n开始请求 🌏 params ==>> \(String(describing: param))")
            }
        }
        
        let encoding: ParameterEncoding = JSONEncoding.default
        
        let req = manager?.request(absolute!,
                                  method: methodType,
                                  parameters: param,
                                  encoding: encoding,
                                  headers: httpHeader)
        
        return req?.responseDecodable(of: type, completionHandler: {[weak self] resp in
            guard let self = self else { return }
            
            if let error :AFError = resp.error {
                self.networkLogFail(error: error, url: urlStr, params: param, remark: remark)
                finished(nil, error.localizedDescription)
                
            } else {
                guard let data = resp.value else {
                    finished(nil, "网络请求解析❌")
                    return
                }
                self.networkLogCodableSuccess(json: data, url: urlStr, params: param, remark: remark)
                finished(data, nil)
            }
        })
    }
   
    // MARK: 上传图片数组, 图片数组的 key 是 images 使用multipart/form-data格式提交图片
    
    /// 上传图片数组
    ///
    /// - Parameters:
    ///   - par: key是 images ，value是 UIImage
    ///   - urlStr: 上传路径
    ///   - finished: 回调
    func upload<T: Codable>(par: [String: Any] , urlStr: String, compressionQuality: Double = 1.0, finished: @escaping networkJSON<T>) {

        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return
        }
        let absolute = ready.1

        let param = appendDefaultParameter(params: par)

        var headers: HTTPHeaders = HTTPHeaders()
        headers["content-type"] = "multipart/form-data"

        _ = manager?.upload(multipartFormData: { (formData) in

            for (key, value) in param! {
                if key == "images" {
                    if let images = value as? [UIImage] {
                        for i in 0..<images.count {
                            let image = images[i]
                            if let imageData = image.jpegData(compressionQuality: compressionQuality) {
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
            WLog("上传图片结果:\(encodingResult)")
//            switch encodingResult {
//            case .success(let upload, _, _):
//                upload.responseJSON(completionHandler: { (resp) in
//                    if resp.result.isSuccess {
//                        let value = resp.result.value as Any?
////                        let js = JSON(value as Any)
////                        self.networkLogSuccess(json: js, url: urlStr, params: nil, remark: nil)
////                        finished(js, nil)
//                    } else {
////                        let error = resp.result.error as NSError?
////                        self.networkLogFail(error: error, url: urlStr, params: nil, remark: nil)
////                        finished(nil, error)
//                    }
//                })
//                break
//            case .failure(let error):
//                let err = error as NSError?
//                finished(nil, err)
//                break
//            }
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
    
    /// 根据固定条件清除缓存
    func autoClearCaches() {
        // 大于等于 10M 后
        if totalCacheSize() >= 1024 * 1024 * 10 {
            clearCaches()
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
        
        let url: URL? = URL(string: absolute!)
        if url == nil {
            if isDebug {
                WLog("URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL, absolute = \(absolute.orNil)")
            }
            return (false, nil)
        }
        
        if manager == nil {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = TimeInterval(timeout)
//            manager = Alamofire.SessionManager(configuration: config)
            manager = Session(configuration: config)
        }
        
        return (true, absolute!)
    }
    
    /// 成功的日志输出
    ///
    /// - Parameters:
    ///   - json: 成功的回调
    ///   - url: 接口
    ///   - params: 参数
    private func networkLogSuccess<T: BaseResp>(json: T?, url: String, params: [String:Any]?, remark: String?) {
        if isDebug {
            let absolute = absoluteUrl(path: url)
            let param: [String: Any] = appendDefaultParameter(params: params) ?? [:]
            if remark.orNil.isEmpty {
                if let json = json {
                    WLog("请求成功🍎, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                } else {
                    WLog("请求成功🍎, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                }
            } else {
                if let json = json {
                    WLog("请求成功🍎, 🌏 \(absolute) \nremark:\(remark.orNil)\nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                } else {
                    WLog("请求成功🍎, 🌏 \(absolute) \nremark:\(remark.orNil)\nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                }
            }
        }
    }
    
    /// - Parameters:
    ///   - json: 成功的回调
    ///   - url: 接口
    ///   - params: 参数
    private func networkLogCodableSuccess<T: Codable>(json: T?, url: String, params: [String:Any]?, remark: String?) {
        if isDebug {
            let absolute = absoluteUrl(path: url)
            let param: [String: Any] = appendDefaultParameter(params: params) ?? [:]
            if remark.orNil.isEmpty {
                if let json = json {
                    WLog("请求成功🍎, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                } else {
                    WLog("请求成功🍎, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                }
            } else {
                if let json = json {
                    WLog("请求成功🍎, 🌏 \(absolute) \nremark:\(remark.orNil)\nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                } else {
                    WLog("请求成功🍎, 🌏 \(absolute) \nremark:\(remark.orNil)\nparams ==>> \(String(describing: param)) \nresponse ==>> \(String(describing: json))")
                }
            }
        }
    }
    
    
    /// 失败的日志输出
    ///
    /// - Parameters:
    ///   - error: 失败信息
    ///   - url: 接口信息
    ///   - params: 参数字典
    private func networkLogFail(error: AFError?, url: String, params: [String:Any]?, remark: String?) {
        if isDebug {
            let absolute = absoluteUrl(path: url)
            let param: [String: Any] = appendDefaultParameter(params: params) ?? [:]
            if error?.responseCode == NSURLErrorCancelled {
                if remark.orNil.isEmpty {
                    WLog("请求被取消🏠, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \n错误信息❌ ==>> \(String(describing: error?.localizedDescription ?? ""))")
                } else {
                    WLog("请求被取消🏠, 🌏 \(absolute) \nremark:\(remark.orNil)\nparams ==>> \(String(describing: param)) \n错误信息❌ ==>> \(String(describing: error?.localizedDescription ?? ""))")
                }
            } else if remark.orNil.isEmpty {
                WLog("请求错误, 🌏 \(absolute) \nparams ==>> \(String(describing: param)) \n错误信息❌ ==>> \(String(describing: error?.localizedDescription ?? ""))")
            } else {
                WLog("请求错误, 🌏 \(absolute) \nremark:\(remark.orNil)\nparams ==>> \(String(describing: param)) \n错误信息❌ ==>> \(String(describing: error?.localizedDescription ?? ""))")
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
    private func cacheResponse<T: BaseResp>(response: T?, url: String, parameters: [String :Any]?) {
        guard let response = response else {
            WLog("❌ 待保存的数据为空")
            return
        }
        
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
        let key = absoluteGet.sha256
        let path = directoryPath.appending("/\(key)")
        
//        WLog("待写入的路径=\(path)")
        
        var data:Data? = nil
        do {
            let encoder = JSONEncoder()
            data = try encoder.encode(response)
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

    
    /// 获取缓存的JSON数据
    ///
    /// - Parameters:
    ///   - url: 外部接口
    ///   - parameters: 参数字典
    /// - Returns: 缓存的JSON数据
    private func getCacheResponse<T: BaseResp>(url: String,
                                                      of type: T.Type,
                                                      parameters: [String :Any]?) -> T? {
        
        let directoryPath = cachePath()
        let absolute = absoluteUrl(path: url)
        let absoluteGet = generateGETAbsoluteURL(url: absolute, params: parameters)
        let key = absoluteGet.sha256
        let path = directoryPath.appending("/\(key)")
        
        if let data = FileManager.default.contents(atPath: path) {
            if let result = try? JSONDecoder().decode(type, from: data) {
                if isDebug {
                    WLog("读取缓存的数据 🌏 \(absoluteGet)")
                }
                return result
            }
        }
        return nil
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
//        var par = params
//        par?["XX-Api-Version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        return par
        return params
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
