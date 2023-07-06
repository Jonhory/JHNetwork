//
//  CheckUpdateResp.swift
//  JHNetwork
//
//  Created by Jonhory on 2023/7/6.
//  Copyright © 2023 com.wujh. All rights reserved.
//

import Foundation

struct DemoResp: BaseResp {
    var code: Int?
    var message: String?
    var status: Int?
    
    let id, subLemmaID, newLemmaID: Int?
    let key, desc, title: String?
    let errno: Int?
    let card: [Card]?
    let image: String?
    let src: String?
    let imageHeight, imageWidth: Int?
    let isSummaryPic, abstract: String?
    let moduleIDS: [Int]?
    let url: String?
    let wapURL: String?
    let hasOther: Int?
    let totalURL: String?
    let catalog, wapCatalog: [String]?
    let logo: String?
    let copyrights, customImg: String?
//    let redirect: [JSONAny]

    enum CodingKeys: String, CodingKey {
        case errno
        case status
        case code
        case message
        
        case id
        case subLemmaID = "subLemmaId"
        case newLemmaID = "newLemmaId"
        case key, desc, title
        case card, image, src, imageHeight, imageWidth, isSummaryPic, abstract
        case moduleIDS = "moduleIds"
        case url
        case wapURL = "wapUrl"
        case hasOther
        case totalURL = "totalUrl"
        case catalog, wapCatalog, logo, copyrights, customImg
//        case redirect
    }
}

// MARK: - Card
struct Card: Codable {

    var key, name: String?
    var value, format: [String]?
}
