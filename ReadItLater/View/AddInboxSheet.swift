//
//  AddInboxSheet.swift
//  ReadItLater
//
//  Created by Claude on 2025/08/14.
//

import SwiftUI

struct AddInboxSheet: View {
    @State private var viewModel = AddInboxViewModel()
    @FocusState private var isURLFieldFocused: Bool

    let onSave: (InboxData) -> Void
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
                        .accessibilityIdentifier("AddInbox.URLField")
                    
                    TextField(titleFieldPlaceholder, text: $viewModel.titleString)
                        .autocapitalization(.words)
                        .accessibilityIdentifier("AddInbox.TitleField")
                } header: {
                    Text("Inbox Details")
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
            .navigationTitle("Add Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveInbox()
                    }
                    .disabled(viewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
            }
        }
        .onAppear {
            isURLFieldFocused = true
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
    
    private func saveInbox() {
        if let inboxData = viewModel.createInbox() {
            onSave(inboxData)
        }
    }
}

#Preview {
    AddInboxSheet(
        onSave: { inboxData in
            print("Save: \(inboxData.url), \(inboxData.title)")
        },
        onCancel: {
            print("Cancel")
        }
    )
}
