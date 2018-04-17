//
//  BroadcastsBindDetail.swift
//  LongHatYoutubeStream
//
//  Created by Reaper on 2017/12/28.
//  Copyright © 2017年 Reaper. All rights reserved.
//

import UIKit
import ObjectMapper

class BindReq: Mappable {
    var id = ""
    var part = "id,snippet,contentDetails,status"
    var streamId = ""
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        id <- map["id"]
        part <- map["part"]
        streamId <- map["streamId"]
    }
}
