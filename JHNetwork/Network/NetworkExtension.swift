//
//  JHNetwork.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/21.
//  Copyright © 2017年 com.wujh. All rights reserved.
//  

import Foundation
import Alamofire

let dateFormatter = DateFormatter()

// MARK: 公共方法
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
    print("\(fileName):(\(lineNum)) \(funcName) \(Date().jh_getDateStr()) \(messsage)")
    #endif
}

extension String {
    
    var sha256: String {
        let utf8 = cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format: "%02x", $1) }
    }
}

extension Date {
    
    func jh_getDateStr() -> String {
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        return dateFormatter.string(from: self)
    }
}

extension String {
    // url encode
    var urlEncode: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    // url decode
    var urlDecode: String? {
        return self.removingPercentEncoding
    }
}

extension Optional {
    var orNil: String {
        if self == nil {
            return ""
        }
        if "\(Wrapped.self)" == "String" {
            return "\(self!)"
        }
        return "\(self!)"
    }
}

// MARK: - 公共工具
extension Network {
    /// 监听网络状态
    ///
    /// - Parameter NetworkListen: 网络状态回调
    func listenNetworkReachabilityStatus(networkListen: @escaping NetworkListen) {
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

extension Network {
    // MARK: 私有方法
    
    // MARK: 准备工作
    func readySendRequest(urlStr: String) -> (Bool, String?) {
        var absolute: String?
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
    
    /// 准备请求的log
    func logReadyNetwork(_ methodType: HTTPMethod, _ remark: String?, _ absolute: String?, _ param: [String: Any]?) {
        if isDebug {
            if remark.orNil.isEmpty {
                WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 params ==>> \(String(describing: param)) \n开始请求 🌏 Method: \(methodType.rawValue)")
            } else {
                WLog("开始请求 🌏 \(absolute.orNil) \n开始请求 🌏 \(remark.orNil) Method: \(methodType.rawValue)\n开始请求 🌏 params ==>> \(String(describing: param))")
            }
        }
    }
    
    /// 成功的日志输出
    ///
    /// - Parameters:
    ///   - json: 成功的回调
    ///   - url: 接口
    ///   - params: 参数
    func networkLogSuccess<T: BaseResp>(json: T?, url: String, params: [String: Any]?, remark: String?) {
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
    func networkLogCodableSuccess<T: Codable>(json: T?, url: String, params: [String: Any]?, remark: String?) {
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
    func networkLogFail(error: AFError?, url: String, params: [String: Any]?, remark: String?) {
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
    func generateGETAbsoluteURL(url: String, params: [String: Any]?) -> String {
        var absoluteUrl = ""
        
        if params != nil {
            let par = appendDefaultParameter(params: params)
            for (key, value): (String, Any) in par! {
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
    func cacheResponse<T: BaseResp>(response: T?, url: String, parameters: [String: Any]?) {
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
        
        var data: Data?
        do {
            let encoder = JSONEncoder()
            data = try encoder.encode(response)
        } catch {
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
    func getCacheResponse<T: BaseResp>(url: String,
                                       of type: T.Type,
                                       parameters: [String: Any]?
    ) -> T? {
        
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
    func absoluteUrl(path: String?) -> String {
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
    func appendDefaultParameter(params: [String: Any]?) -> [String: Any]? {
//        var par = params
//        par?["XX-Api-Version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        return par
        return params
    }
    
    /// 获取缓存的文件夹路径
    ///
    /// - Returns: 文件夹路径
    func cachePath() -> String {
        return NSHomeDirectory().appending("/Library/Caches/JHNetworkCaches")
    }
}
