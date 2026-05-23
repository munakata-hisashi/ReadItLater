//
//  AppColor.swift
//  ReadItLater
//
//  Created by Codex on 2026/02/25.
//

import SwiftUI

extension Color {
    static let appBrandPrimary = Color("BrandPrimary")
    static let appBrandSecondary = Color("BrandSecondary")
    static let appBrandAccent = Color("BrandAccent")

    static let appBackgroundBase = Color("BackgroundBase")
    static let appCardBackground = Color("CardBackground")
    static let appTextPrimary = Color("TextPrimary")
    static let appTextSecondary = Color("TextSecondary")

    // Swipe actions keep semantic meaning while sharing app tokens.
    static let appSwipeInbox = Color.appBrandAccent
    static let appSwipeBookmark = Color.appBrandSecondary
    static let appSwipeArchive = Color.appBrandPrimary
}
