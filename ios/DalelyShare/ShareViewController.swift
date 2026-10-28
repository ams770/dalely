import CoreLocation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class TransparentHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
        view.isOpaque = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.backgroundColor = .clear
        view.isOpaque = false
    }
}

@objc(ShareViewController)
final class ShareViewController: UIViewController {
    override func loadView() {
        let v = UIView()
        v.backgroundColor = .clear
        v.isOpaque = false
        self.view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false

        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 28
        }

        extractSharedContent { [weak self] rawContent, defaultLabel in
            guard let self else { return }
            self.presentShareSheet(rawContent: rawContent, defaultLabel: defaultLabel)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearBackgrounds()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        clearBackgrounds()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clearBackgrounds()
    }

    private func clearBackgrounds() {
        view.backgroundColor = .clear
        view.isOpaque = false
        view.superview?.backgroundColor = .clear
        view.superview?.isOpaque = false
        view.window?.backgroundColor = .clear
        view.window?.isOpaque = false
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

    private func presentShareSheet(rawContent: String?, defaultLabel: String?) {
        let sheetView = ShareSpotSheetView(
            rawSharedText: rawContent,
            suggestedLabel: defaultLabel,
            onSave: { [weak self] spot in
                self?.saveSpotAndFinish(spot)
            },
            onCancel: { [weak self] in
                self?.cancelAndFinish()
            }
        )

        let hosting = TransparentHostingController(rootView: sheetView)
        hosting.modalPresentationStyle = .overFullScreen
        hosting.view.backgroundColor = .clear
        hosting.view.isOpaque = false

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

    private func saveSpotAndFinish(_ spot: Spot) {
        var existing = LocalStore.loadSpots()
        existing.append(spot)
        LocalStore.saveSpots(existing)

        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)

        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func cancelAndFinish() {
        extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0, userInfo: nil))
    }
}
