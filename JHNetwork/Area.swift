//
//  Area.swift
//  JHNetwork
//
//  Created by Jonhory on 2017/2/28.
//  Copyright © 2017年 com.wujh. All rights reserved.
//

import Foundation
import ObjectMapper

class Area: Mappable {
    var district: String?
    var city: String?
    var ret: Int = 0
    var desc: String?
    var isp: String?
    var end: Int = 0
    var start: Int = 0
    var province: String?
    var type: String?
    var country: String?
    
    required init?(map: Map) {
        
    }
    func mapping(map: Map) {
        district <- map["district"]
        city <- map["city"]
        ret <- map["ret"]
        desc <- map["desc"]
        end <- map["end"]
        start <- map["start"]
        province <- map["province"]
        type <- map["type"]
        country <- map["country"]
    }
}

class Country : Area {
    var name: String?
    var area: Area?
    var areas: [Area]?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        name <- map["name"]
    }
}
