//
//  Bookmark.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/14.
//

import Foundation

typealias Bookmark = AppV2Schema.Bookmark

extension Bookmark {
    var safeTitle: String {
        title ?? "No title"
    }
    
    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
