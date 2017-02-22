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

class JHNetwork{
    //MARK:单例
    static let shared = JHNetwork()
    private init() {}
    
    typealias failture = (_ error : Error) -> Void
    typealias success = (_ success : DataResponse<Any>) -> Void
}

extension JHNetwork{//@escaping
    func getWithUrl(url: String, success: @escaping success, failture: @escaping failture) -> Void {
        Alamofire.request(url, method: .get).responseJSON{ (response) in
            success(response)
        }
    }
    
    
}


