//
//  AddBookmarkSheet.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import SwiftUI

struct AddBookmarkSheet: View {
    @State private var viewModel = AddBookmarkViewModel()
    @FocusState private var isURLFieldFocused: Bool
    
    let onSave: (BookmarkData) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("URL", text: $viewModel.urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isURLFieldFocused)
                    
                    TextField("Title (Optional)", text: $viewModel.titleString)
                        .autocapitalization(.words)
                } header: {
                    Text("Bookmark Details")
                } footer: {
                    Text("Enter a valid URL (http:// or https://)")
                }
                
                if let errorMessage = viewModel.errorMessage {
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
                        Task {
                            await saveBookmark()
                        }
                    }
                    .disabled(viewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
            }
        }
        .onAppear {
            isURLFieldFocused = true
        }
    }
    
    @MainActor
    private func saveBookmark() async {
        let success = await viewModel.createBookmark()
        if success {
            // ドメインモデルから成功時のBookmarkDataを取得
            let result = Bookmark.create(from: viewModel.urlString, title: viewModel.titleString.isEmpty ? nil : viewModel.titleString)
            if case .success(let bookmarkData) = result {
                onSave(bookmarkData)
            }
        }
    }
}

#Preview {
    AddBookmarkSheet(
        onSave: { bookmarkData in
            print("Save: \(bookmarkData.url), \(bookmarkData.title)")
        },
        onCancel: {
            print("Cancel")
        }
    )
}