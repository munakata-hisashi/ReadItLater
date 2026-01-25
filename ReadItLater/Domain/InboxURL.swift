//
//  InboxURL.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import Foundation

struct InboxURL {
    private let rawURL: String
    
    init(_ urlString: String) throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw URLValidationError.emptyURL
        }
        
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased() else {
            throw URLValidationError.invalidFormat
        }
        
        guard ["http", "https"].contains(scheme) else {
            throw URLValidationError.unsupportedScheme
        }
        
        // Additional validation: must have host for http/https URLs
        guard url.host != nil else {
            throw URLValidationError.invalidFormat
        }
        
        self.rawURL = trimmed
    }
    
    var value: String {
        return rawURL
    }
    
    var extractedTitle: String {
        guard let url = URL(string: rawURL),
              let host = url.host else {
            return "Untitled Inbox"
        }
        
        // Remove www. prefix if present
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        // Capitalize first letter of each component separated by dots
        let components = cleanHost.components(separatedBy: ".")
        let capitalizedComponents = components.map { component in
            guard !component.isEmpty else { return component }
            return component.prefix(1).uppercased() + component.dropFirst()
        }
        
        return capitalizedComponents.joined(separator: ".")
    }
    
    var normalizedURL: String {
        return rawURL
    }
}