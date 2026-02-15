//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 宗像恒 on 2026/01/05.
//

import UIKit
import SwiftData

@MainActor
final class ShareViewController: UIViewController {

    private enum UIState {
        case loading
        case readyToSave
        case saving
        case success
        case failure(InboxSaveError)
    }

    private var modelContainer: ModelContainer?
    private var repository: InboxRepository?
    private var metadataService: URLMetadataService?

    private var sharedURL: URL?
    private var sharedTitle: String?

    private let titleLabel = UILabel()
    private let urlLabel = UILabel()
    private let inboxCountLabel = UILabel()
    private let statusLabel = UILabel()

    private let saveButton = UIButton(type: .system)
    private let openAppButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupDependenciesAndLoad()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            urlLabel,
            inboxCountLabel,
            statusLabel,
            saveButton,
            openAppButton,
            closeButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, urlLabel, inboxCountLabel, statusLabel].forEach {
            $0.numberOfLines = 0
            $0.font = .preferredFont(forTextStyle: .body)
        }

        statusLabel.textColor = .secondaryLabel

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        openAppButton.setTitle("アプリを開く", for: .normal)
        openAppButton.addTarget(self, action: #selector(didTapOpenApp), for: .touchUpInside)

        closeButton.setTitle("閉じる", for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        apply(state: .loading)
    }

    private func setupDependenciesAndLoad() {
        do {
            let container = try ModelContainerFactory.createSharedContainer()
            modelContainer = container

            let context = ModelContext(container)
            repository = InboxRepository(modelContext: context)
            metadataService = URLMetadataService()

            Task {
                await loadShareItemPreview()
            }
        } catch {
            apply(state: .failure(.containerInitFailed))
        }
    }

    private func loadShareItemPreview() async {
        guard let repository else {
            apply(state: .failure(.containerInitFailed))
            return
        }

        let itemProvider = ExtensionItemProvider(extensionContext: extensionContext)

        do {
            let (url, maybeTitle) = try await itemProvider.extractURLAndTitle()
            let resolvedTitle = await resolveTitle(url: url, maybeTitle: maybeTitle)

            sharedURL = url
            sharedTitle = resolvedTitle

            titleLabel.text = "タイトル: \(resolvedTitle ?? "(取得できませんでした)")"
            urlLabel.text = "URL: \(url.absoluteString)"
            inboxCountLabel.text = "現在のInbox件数: \(repository.count())件"

            apply(state: .readyToSave)
        } catch let error as InboxSaveError {
            apply(state: .failure(error))
        } catch {
            apply(state: .failure(.noURLFound))
        }
    }

    private func resolveTitle(url: URL, maybeTitle: String?) async -> String? {
        if let maybeTitle, !maybeTitle.isEmpty {
            return maybeTitle
        }

        guard let metadataService else {
            return nil
        }

        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            return metadata.title
        } catch {
            return nil
        }
    }

    @objc
    private func didTapSave() {
        Task {
            await saveSharedItem()
        }
    }

    private func saveSharedItem() async {
        guard let repository,
              let metadataService,
              let sharedURL else {
            apply(state: .failure(.containerInitFailed))
            return
        }

        apply(state: .saving)

        let useCase = SaveToInboxUseCase(
            metadataService: metadataService,
            repository: repository
        )

        let result = await useCase.execute(
            urlString: sharedURL.absoluteString,
            title: sharedTitle
        )

        switch result {
        case .success:
            inboxCountLabel.text = "現在のInbox件数: \(repository.count())件"
            apply(state: .success)

            Task {
                try? await Task.sleep(for: .seconds(0.8))
                extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        case .failure(let error):
            apply(state: .failure(error))
        }
    }

    @objc
    private func didTapOpenApp() {
        guard let url = URL(string: "readitlater://inbox") else {
            return
        }

        extensionContext?.open(url) { [weak self] success in
            Task { @MainActor in
                guard let self else { return }
                if success {
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    return
                }

                // Share Extension環境ではextensionContext.openが失敗することがあるため、
                // responder chain経由でopenURL:をフォールバック実行する。
                self.openAppViaResponderChain(url)
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }

    private func openAppViaResponderChain(_ url: URL) {
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if currentResponder.responds(to: selector) {
                _ = currentResponder.perform(selector, with: url)
                return
            }
            responder = currentResponder.next
        }
    }

    @objc
    private func didTapClose() {
        let cancelError = NSError(domain: "ShareExtension", code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: cancelError)
    }

    private func apply(state: UIState) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            saveButton.isHidden = true
            openAppButton.isHidden = true
            closeButton.isHidden = true
            statusLabel.text = "共有情報を取得しています..."
            statusLabel.textColor = .secondaryLabel

        case .readyToSave:
            activityIndicator.stopAnimating()
            saveButton.isHidden = false
            saveButton.isEnabled = true
            openAppButton.isHidden = true
            closeButton.isHidden = false
            statusLabel.text = "保存内容を確認して「保存」を押してください"
            statusLabel.textColor = .secondaryLabel

        case .saving:
            activityIndicator.startAnimating()
            saveButton.isEnabled = false
            openAppButton.isHidden = true
            closeButton.isHidden = true
            statusLabel.text = "保存中です..."
            statusLabel.textColor = .secondaryLabel

        case .success:
            activityIndicator.stopAnimating()
            saveButton.isHidden = true
            openAppButton.isHidden = true
            closeButton.isHidden = true
            statusLabel.text = "保存に成功しました。シートを閉じます。"
            statusLabel.textColor = .systemGreen

        case .failure(let error):
            activityIndicator.stopAnimating()
            saveButton.isHidden = false
            saveButton.isEnabled = true
            closeButton.isHidden = false
            statusLabel.text = "保存に失敗しました: \(error.localizedDescription)"
            statusLabel.textColor = .systemRed

            if error == .inboxFull {
                openAppButton.isHidden = false
            } else {
                openAppButton.isHidden = true
            }
        }
    }
}
