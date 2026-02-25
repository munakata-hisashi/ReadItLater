//
//  HideTabBarKey.swift
//  ReadItLater
//

import SwiftUI

private struct HideFloatingTabBarKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var hideFloatingTabBar: Binding<Bool> {
        get { self[HideFloatingTabBarKey.self] }
        set { self[HideFloatingTabBarKey.self] = newValue }
    }
}
