//
//  YoutubeStreamResponse.swift
//  LongHatYoutubeStream
//
//  Created by Reaper on 2017/12/27.
//  Copyright © 2017年 Reaper. All rights reserved.
//

import UIKit
import ObjectMapper

class Broadcasts: Mappable{
    var items = [BroadcastsItems]()
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        items <- map["items"]
    }
}

class BroadcastsItems: Mappable {
    var snippet = BroadcastsSnippet()
    var status = BroadcastsStatus()
    var contentDetails = BroadcastsContentDetails()
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        snippet <- map["snippet"]
        status <- map["status"]
        contentDetails <- map["contentDetails"]
    }
}

class BroadcastsSnippet: Mappable {
    var title = ""
    var description = ""
    var scheduledStartTime = ""

    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        title <- map["title"]
        description <- map["description"]
        scheduledStartTime <- map["scheduledStartTime"]
    }
}

class BroadcastsStatus: Mappable {
    var privacyStatus = ""
    var lifeCycleStatus = ""
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        privacyStatus <- map["privacyStatus"]
        lifeCycleStatus <- map["lifeCycleStatus"]
    }
}

class BroadcastsContentDetails: Mappable {
    var enableLowLatency : Bool!
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        enableLowLatency <- map["enableLowLatency"]
    }
}


class BroadcastsRes: Mappable {
    var id = ""
    
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        id <- map["id"]
    }
}






