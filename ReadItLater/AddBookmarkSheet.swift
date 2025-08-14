//
//  AddBookmarkSheet.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import SwiftUI

struct AddBookmarkSheet: View {
    @State private var urlText: String = ""
    @State private var title: String = ""
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isURLFieldFocused: Bool
    
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("URL", text: $urlText)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isURLFieldFocused)
                        .onSubmit {
                            validateAndExtractTitle()
                        }
                    
                    TextField("Title (Optional)", text: $title)
                        .autocapitalization(.words)
                } header: {
                    Text("Bookmark Details")
                } footer: {
                    Text("Enter a valid URL (http:// or https://)")
                }
                
                if showingError {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBookmark()
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isURLFieldFocused = true
        }
    }
    
    private func validateAndExtractTitle() {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty else {
            showError("Please enter a URL")
            return
        }
        
        guard isValidURL(trimmedURL) else {
            showError("Please enter a valid URL (must start with http:// or https://)")
            return
        }
        
        clearError()
        
        // If title is empty, try to extract from URL
        if title.isEmpty {
            title = extractTitleFromURL(trimmedURL)
        }
    }
    
    private func saveBookmark() {
        validateAndExtractTitle()
        
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = title.isEmpty ? extractTitleFromURL(trimmedURL) : title
        
        if !showingError && isValidURL(trimmedURL) {
            onSave(trimmedURL, finalTitle)
        }
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    private func extractTitleFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return "Untitled Bookmark"
        }
        
        // Remove www. prefix if present
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return cleanHost.capitalized
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func clearError() {
        showingError = false
        errorMessage = ""
    }
}

#Preview {
    AddBookmarkSheet(
        onSave: { url, title in
            print("Save: \(url), \(title)")
        },
        onCancel: {
            print("Cancel")
        }
    )
}