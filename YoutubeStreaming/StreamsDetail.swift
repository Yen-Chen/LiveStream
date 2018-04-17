//
//  StreamsDetail.swift
//  LongHatYoutubeStream
//
//  Created by Reaper on 2017/12/28.
//  Copyright © 2017年 Reaper. All rights reserved.
//

import UIKit
import ObjectMapper

class StreamsReq: Mappable{
    var items = [StreamsItems]()
     
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        items <- map["items"]
    }
}

class StreamsItems: Mappable {
    var snippet = StreamsSnippet()
    var cdn = StreamsCdn()
    var status = StreamsStatus()
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        snippet <- map["snippet"]
        cdn <- map["cdn"]
        status <- map["status"]
    }
}

class StreamsSnippet: Mappable {
    var title = ""
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        title <- map["title"]
    }
}

class StreamsCdn: Mappable {
    var resolution = ""
    var frameRate = ""
    var ingestionType = ""
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        resolution <- map["resolution"]
        frameRate <- map["frameRate"]
        ingestionType <- map["ingestionType"]
    }
}

class StreamsStatus: Mappable {
    var streamStatus = ""
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        streamStatus <- map["streamStatus"]
    }
}


class StreamsRes: Mappable {
    var id = ""
    var cdn = StreamCdn()
    
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        id <- map["id"]
        cdn <- map["cdn"]
    }
}



class StreamCdn: Mappable {
    var ingestionInfo = IngestionInfo()
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        ingestionInfo <- map["ingestionInfo"]
    }
    
}
class IngestionInfo: Mappable {
    var streamName = ""
    
    init() {}
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        streamName <- map["streamName"]
    }
    
}
