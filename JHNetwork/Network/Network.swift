//
//  JHNetwork.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//  

import UIKit
import Alamofire

typealias BaseResp = BaseRespCodable & Decodable & Encodable

protocol BaseRespCodable {
    var code: Int? { get set}
    var message: String? {get set}
}

class Network {
    
    // MARK: 单例
    static let shared = Network()
    private init() {}
    
    /// JSON数据回调
    typealias NetworkJSONCallback<T: BaseResp> = (_ result: T?, _ error: String?) -> Void
    typealias NetworkCodable<T: Codable> = (_ result: T?, _ error: String?) -> Void
    
    /// 网络状态监听回调
    typealias NetworkListen = (_ status: NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
    
    /// 网络基础url
    var baseUrl: String?
    /// 请求超时
    var timeout = 20
    /// 配置公共请求头
    var httpHeader: HTTPHeaders?
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
    func shoulObtainLocalWhenUnconnected(shouldObtain: Bool) {
        shoulObtainLocalWhenUnconnected = shouldObtain
        if shouldObtain {
            listenNetworkReachabilityStatus {_ in }
        }
    }
}

// MARK: - 网络请求相关
extension Network {
    
    // MARK: - 缓存相关
    /// 获取之前的缓存结果
    @discardableResult
    func getCacheForJSON<T: BaseResp>(url: String, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return getForJSON(url: url, refreshCache: false, parameters: parameters, remark: remark, of: type) { (js, _) in
            finished(js, nil)
        }
    }

    // MARK: 缓存GET
    @discardableResult
    func getForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return getForJSON(url: url, parameters: nil, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getForJSON<T: BaseResp>(url: String, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return getForJSON(url: url, refreshCache: true, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getForJSON<T: BaseResp>(url: String, refreshCache: Bool, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return request(methodType: .get, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    // MARK: 不缓存GET
    @discardableResult
    func getNoCacheForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return getNoCacheForJSON(url: url, parameters: nil, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getNoCacheForJSON<T: BaseResp>(url: String, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return getNoCacheForJSON(url: url, refreshCache: true, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    @discardableResult
    func getNoCacheForJSON<T: BaseResp>(url: String,
                                        refreshCache: Bool,
                                        parameters: [String: Any]?,
                                        remark: String? = nil,
                                        of type: T.Type,
                                        finished: @escaping NetworkJSONCallback<T>
    ) -> DataRequest? {
        return request(methodType: .get, urlStr: url, refreshCache: refreshCache, isCache: false, parameters: parameters, remark: remark, of: type, finished: finished)
    }

    // MARK: 缓存POST
    @discardableResult
    func postForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return postForJSON(url: url, parameters: nil, of: type, finished: finished)
    }

    @discardableResult
    func postForJSON<T: BaseResp>(url: String, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return postForJSON(url: url, refreshCache: true, parameters: parameters, of: type, finished: finished)
    }

    @discardableResult
    func postForJSON<T: BaseResp>(url: String, refreshCache: Bool, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return request(methodType: .post, urlStr: url, refreshCache: refreshCache, isCache: true, parameters: parameters, of: type, finished: finished)
    }

    // MARK: 不缓存POST
    @discardableResult
    func postNoCacheForJSON<T: BaseResp>(url: String, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return postNoCacheForJSON(url: url, parameters: nil, of: type, finished: finished)
    }

    @discardableResult
    func postNoCacheForJSON<T: Codable>(url: String, parameters: [String: Any]?, remark: String? = nil, of type: T.Type, finished: @escaping NetworkJSONCallback<T>) -> DataRequest? {
        return postNoCacheForJSON(url: url, refreshCache: true, parameters: parameters, of: type, finished: finished)
    }

    @discardableResult
    func postNoCacheForJSON<T: BaseResp>(url: String,
                                         refreshCache: Bool,
                                         parameters: [String: Any]?,
                                         remark: String? = nil,
                                         of type: T.Type,
                                         finished: @escaping NetworkJSONCallback<T>
    ) -> DataRequest? {
        return request(methodType: .post, urlStr: url, refreshCache: refreshCache, isCache: false, parameters: parameters, of: type, finished: finished)
    }
    
    // MARK: 请求JSON数据最底层
    
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
        methodType: HTTPMethod = .get,
        urlStr: String,
        refreshCache: Bool = true,
        isCache: Bool = true,
        parameters: [String: Any]?,
        remark: String? = nil,
        of type: T.Type,
        codeHandler: Bool = true,
        finished: @escaping NetworkJSONCallback<T>
    ) -> DataRequest? {
        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return nil
        }
        let absolute = ready.1
        let param: [String: Any]? = appendDefaultParameter(params: parameters)
       
        logReadyNetwork(methodType, remark, absolute, param)
        
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
            // 如果不刷新缓存，如果已存在缓存，则返回缓存，否则请求网络，但是不缓存数据
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
            
            if let error: AFError = resp.error {
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
        methodType: HTTPMethod = .get,
        urlStr: String,
        parameters: [String: Any]?,
        remark: String? = nil,
        of type: T.Type,
        finished: @escaping NetworkCodable<T>
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
            
            if let error: AFError = resp.error {
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
    func upload<T: Codable>(par: [String: Any], urlStr: String, compressionQuality: Double = 1.0, finished: @escaping NetworkJSONCallback<T>) {

        let ready = readySendRequest(urlStr: urlStr)
        if ready.0 == false {
            return
        }
        let absolute = ready.1

        let param = appendDefaultParameter(params: par)

        var headers: HTTPHeaders = HTTPHeaders()
        headers["content-type"] = "multipart/form-data"

        manager?.upload(multipartFormData: { (formData) in

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

        }, to: absolute!, headers: headers).response(completionHandler: { encodingResult in
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
        })
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
                    } catch {
                        if isDebug {
                            WLog("‼️失败==\(error)")
                        }
                    }
                    
                }
            } catch {
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
                } catch {
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
}
