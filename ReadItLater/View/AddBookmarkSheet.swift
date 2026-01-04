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
    @State private var fetchTask: Task<Void, Never>?

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
                    
                    TextField(titleFieldPlaceholder, text: $viewModel.titleString)
                        .autocapitalization(.words)
                } header: {
                    Text("Bookmark Details")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter a valid URL (http:// or https://)")
                        
                        if viewModel.isFetchingMetadata {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Fetching page title...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let fetchedTitle = viewModel.fetchedTitle,
                           viewModel.titleString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                viewModel.titleString = fetchedTitle
                            } label: {
                                Text("Suggested title: \(fetchedTitle)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
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
        .onChange(of: viewModel.urlString) { _, newValue in
            // 前回のタスクをキャンセル
            fetchTask?.cancel()

            fetchTask = Task {
                // 0.5秒のデバウンス
                try? await Task.sleep(nanoseconds: 500_000_000)

                // キャンセルされていないか確認
                guard !Task.isCancelled else { return }

                // URL文字列が変更されていないか確認
                if viewModel.urlString == newValue {
                    await viewModel.fetchMetadataIfNeeded()
                }
            }
        }
    }
    
    private var titleFieldPlaceholder: String {
        if let fetchedTitle = viewModel.fetchedTitle,
           viewModel.titleString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fetchedTitle
        } else {
            return "Title (Optional)"
        }
    }
    
    @MainActor
    private func saveBookmark() async {
        let success = viewModel.createBookmark()
        if success {
            // ドメインモデルから成功時のBookmarkDataを取得
            let trimmedTitle = viewModel.titleString.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalTitle = trimmedTitle.isEmpty ? viewModel.fetchedTitle : trimmedTitle
            let result = Bookmark.create(from: viewModel.urlString, title: finalTitle)
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
