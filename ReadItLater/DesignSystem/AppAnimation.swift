//
//  AppAnimation.swift
//  ReadItLater
//

import SwiftUI

enum AppAnimation {
    static let standard = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}
