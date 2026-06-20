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
    @Query(
        filter: #Predicate<URLItem> { $0.status == "archive" },
        sort: \URLItem.archivedAt,
        order: .reverse
    ) private var archiveItems: [URLItem]
    @State private var searchText = ""
    @State private var showingExporter = false
    @State private var exportDocument: ArchiveExportDocument?
    @State private var exportFilename = ""
    @State private var exportErrorMessage: String?
    @State private var showingExportError = false
    @State private var actionFeedbackTrigger = 0

    /// Repository（computed propertyとして生成）
    private var repository: ArchiveRepositoryProtocol {
        ArchiveRepository(modelContext: modelContext)
    }

    private var inboxRepository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    private let exportUseCase = ArchiveExportUseCase()

    /// 検索入力をトリムした文字列（空白のみ入力は空として扱う）
    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 検索フィルタ済みのアイテム
    private var filteredItems: [URLItem] {
        archiveItems.filter { $0.matches(searchText: normalizedSearchText) }
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
                .urlItemListRowStyle()
            }
        }
        .urlItemListScreenStyle()
        .overlay {
            if filteredItems.isEmpty {
                if normalizedSearchText.isEmpty {
                    URLItemEmptyStateView(
                        systemImage: "archivebox",
                        title: "Archiveは空です",
                        message: "読み終えた項目をArchiveに移すと、ここで一覧できます。"
                    )
                } else {
                    URLItemEmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "検索結果がありません",
                        message: "別のキーワードで検索するか、検索条件をクリアしてください。",
                        actionTitle: "検索をクリア",
                        action: {
                            withAnimation(.smooth) {
                                searchText = ""
                            }
                        }
                    )
                }
            }
        }
        .searchable(text: $searchText, prompt: "タイトルまたはURLで検索")
        .navigationTitle("Archive")
        .navigationDestination(for: URLItem.self) { archive in
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
        .tint(Color.appBrandPrimary)
        .sensoryFeedback(.success, trigger: actionFeedbackTrigger)
    }

    private func moveToInbox(_ archive: URLItem) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToInbox(archive, using: inboxRepository)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ archive: URLItem) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToBookmark(archive)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func deleteArchive(_ archive: URLItem) {
        withAnimation(.bouncy) {
            repository.delete(archive)
            actionFeedbackTrigger += 1
        }
    }

    private func exportArchives() {
        do {
            let items = filteredItems.compactMap { ArchiveExportItem(archive: $0) }
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
