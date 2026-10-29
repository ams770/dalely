import CoreLocation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareSpotViewModel: ObservableObject {
    @Published var rawContent: String?
    @Published var suggestedLabel: String?
    @Published var isContentExtracted: Bool = false

    func update(rawContent: String?, suggestedLabel: String?) {
        self.rawContent = rawContent
        self.suggestedLabel = suggestedLabel
        self.isContentExtracted = true
    }
}

@objc(ShareViewController)
final class ShareViewController: UIViewController, UISheetPresentationControllerDelegate {
    private var hasFinished = false
    private let viewModel = ShareSpotViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        if let sheet = sheetPresentationController {
            let contentDetent = UISheetPresentationController.Detent.custom(identifier: .init("contentFit")) { _ in
                return 390
            }
            sheet.detents = [contentDetent, .large()]
            sheet.selectedDetentIdentifier = contentDetent.identifier
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.delegate = self
        }
        presentationController?.delegate = self

        setupHostingController()

        extractSharedContent { [weak self] rawContent, defaultLabel in
            guard let self else { return }
            self.viewModel.update(rawContent: rawContent, suggestedLabel: defaultLabel)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !hasFinished {
            cancelAndFinish()
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        cancelAndFinish()
    }

    private func setupHostingController() {
        let sheetView = ShareSpotSheetView(
            viewModel: viewModel,
            onSave: { [weak self] spot in
                self?.saveSpotAndFinish(spot)
            },
            onCancel: { [weak self] in
                self?.cancelAndFinish()
            }
        )

        let hosting = UIHostingController(rootView: sheetView)
        hosting.view.backgroundColor = .clear

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hosting.didMove(toParent: self)
    }

    private func extractSharedContent(completion: @escaping (String?, String?) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem],
              let firstItem = items.first,
              let attachments = firstItem.attachments,
              !attachments.isEmpty else {
            completion(nil, nil)
            return
        }

        let label = firstItem.attributedContentText?.string

        // 1. Try public.url
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    let urlStr: String?
                    if let url = item as? URL {
                        urlStr = url.absoluteString
                    } else if let str = item as? String {
                        urlStr = str
                    } else {
                        urlStr = nil
                    }
                    DispatchQueue.main.async {
                        completion(urlStr, label)
                    }
                }
                return
            }
        }

        // 2. Try public.plain-text
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    let text = item as? String
                    DispatchQueue.main.async {
                        completion(text, label)
                    }
                }
                return
            }
        }

        completion(nil, label)
    }

    private func saveSpotAndFinish(_ spot: Spot) {
        guard !hasFinished else { return }
        hasFinished = true

        var existing = LocalStore.loadSpots()
        existing.append(spot)
        LocalStore.saveSpots(existing)

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)

        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func cancelAndFinish() {
        guard !hasFinished else { return }
        hasFinished = true
        extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0, userInfo: nil))
    }
}
