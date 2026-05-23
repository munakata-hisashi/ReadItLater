//
//  ArchiveListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct ArchiveListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Archive.archivedAt, order: .reverse) private var archiveItems: [Archive]
    @State private var searchText = ""
    @State private var showingExporter = false
    @State private var exportDocument: ArchiveExportDocument?
    @State private var exportFilename = ""
    @State private var exportErrorMessage: String?
    @State private var showingExportError = false

    /// Repository（computed propertyとして生成）
    private var repository: ArchiveRepositoryProtocol {
        ArchiveRepository(modelContext: modelContext)
    }

    private var inboxRepository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    private let exportUseCase = ArchiveExportUseCase()

    /// 検索フィルタ済みのアイテム
    private var filteredItems: [Archive] {
        archiveItems.filter { $0.matches(searchText: searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredItems) { archive in
                NavigationLink(value: archive) {
                    URLItemRow(item: archive)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    InboxSwipeButton {
                        moveToInbox(archive)
                    }
                    BookmarkSwipeButton {
                        moveToBookmark(archive)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    DeleteSwipeButton {
                        deleteArchive(archive)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "タイトルまたはURLで検索")
        .navigationTitle("Archive")
        .navigationDestination(for: Archive.self) { archive in
            URLItemDetailView(item: archive)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportArchives) {
                    Label("Export URLs", systemImage: "square.and.arrow.up")
                }
                .disabled(filteredItems.isEmpty)
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result, !isUserCancelled(error) {
                showExportError(message: error.localizedDescription)
            }

            exportDocument = nil
        }
        .alert("エクスポートできませんでした", isPresented: $showingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "不明なエラーが発生しました。")
        }
    }

    private func moveToInbox(_ archive: Archive) {
        withAnimation {
            do {
                try repository.moveToInbox(archive, using: inboxRepository)
            } catch {
                print("Failed to move to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ archive: Archive) {
        withAnimation {
            do {
                try repository.moveToBookmark(archive)
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func deleteArchive(_ archive: Archive) {
        withAnimation {
            repository.delete(archive)
        }
    }

    private func exportArchives() {
        do {
            let items = filteredItems.map { ArchiveExportItem(archive: $0) }
            let export = try exportUseCase.execute(items: items)
            exportDocument = ArchiveExportDocument(data: export.data)
            exportFilename = export.filename
            showingExporter = true
        } catch let error as ArchiveExportError {
            showExportError(message: message(for: error))
        } catch {
            showExportError(message: error.localizedDescription)
        }
    }

    private func showExportError(message: String) {
        exportErrorMessage = message
        showingExportError = true
    }

    private func message(for error: ArchiveExportError) -> String {
        switch error {
        case .emptyArchives:
            return "エクスポートするアーカイブがありません。"
        case .encodingFailed:
            return "エクスポートデータの作成に失敗しました。"
        }
    }

    private func isUserCancelled(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == CocoaError.userCancelled.rawValue
    }
}

#Preview {
    NavigationStack {
        ArchiveListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
