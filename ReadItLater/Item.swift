//
//  Item.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//

import Foundation
import SwiftData

typealias Item = AppV1Schema.Item

extension Item {
    var safeTitle: String {
        title ?? "No title"
    }
    
    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
