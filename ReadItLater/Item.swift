//
//  Item.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
