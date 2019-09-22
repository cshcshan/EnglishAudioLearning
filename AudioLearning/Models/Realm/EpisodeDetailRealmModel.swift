//
//  EpisodeDetailRealmModel.swift
//  AudioLearning
//
//  Created by Han Chen on 2019/9/22.
//  Copyright © 2019 cshan. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers
class EpisodeDetailRealmModel: Object {
    dynamic var id: String? // UUID
    dynamic var path: String?
    dynamic var scriptHtml: String?
    dynamic var audioLink: String?
    
    override static func primaryKey() -> String {
        return "id"
    }
}