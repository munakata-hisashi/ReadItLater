//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 宗像恒 on 2026/01/05.
//

import UIKit
import SwiftData

final class ShareViewController: UIViewController {

    private var modelContainer: ModelContainer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ModelContainer初期化
        do {
            modelContainer = try ModelContainerFactory.createSharedContainer()
        } catch {
            completeRequest(with: .failure(InboxSaveError.containerInitFailed))
            return
        }

        // URL処理
        Task {
            await processSharedURL()
        }
    }

    private func processSharedURL() async {
        guard let container = modelContainer else {
            completeRequest(with: .failure(InboxSaveError.containerInitFailed))
            return
        }

        // 依存性を組み立て
        let itemProvider = ExtensionItemProvider(extensionContext: extensionContext)
        let metadataService = URLMetadataService()
        let context = ModelContext(container)
        let repository = InboxRepository(modelContext: context)

        // UseCaseを実行
        let useCase = ShareURLUseCase(
            itemProvider: itemProvider,
            metadataService: metadataService,
            repository: repository
        )

        let result = await useCase.execute()
        completeRequest(with: result)
    }

    private func completeRequest(with result: Result<Void, InboxSaveError>) {
        switch result {
        case .success:
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        case .failure(let error):
            // エラーメッセージをアラートで表示
            showErrorAlert(error) {
                self.extensionContext?.cancelRequest(withError: error as NSError)
            }
        }
    }

    private func showErrorAlert(_ error: Error, completion: @escaping () -> Void) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription

        let alert = UIAlertController(
            title: "エラー",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion()
        })

        present(alert, animated: true)
    }
}
