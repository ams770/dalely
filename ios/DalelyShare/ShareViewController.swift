import UIKit
import Social
import CoreServices
import UniformTypeIdentifiers
import MapKit
import ObjectiveC.runtime

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let appGroupId = "group.com.dalely.app"
    private let keyPendingAction = "pending_notification_action"
    private let keyPendingTime = "pending_notification_time"
    private let keyPendingData = "pending_notification_data"

    private var hasProcessed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasProcessed {
            hasProcessed = true
            processSharedItems()
        }
    }

    // MARK: - Process Items

    private func processSharedItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem], !items.isEmpty else {
            dismissExtension()
            return
        }

        var sharedUrl: URL?
        var sharedText: String?
        let group = DispatchGroup()

        for item in items {
            if let text = item.attributedContentText?.string,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sharedText = text
            }

            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // 1. Apple Maps MKMapItem
                if provider.hasItemConformingToTypeIdentifier("com.apple.mapkit.map-item") {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: "com.apple.mapkit.map-item", options: nil) { (item, _) in
                        defer { group.leave() }
                        if let mapItem = item as? MKMapItem {
                            let coord = mapItem.placemark.coordinate
                            let name = mapItem.name ?? ""
                            let mapUrlStr = "https://maps.apple.com/?ll=\(coord.latitude),\(coord.longitude)&q=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
                            if sharedUrl == nil, let url = URL(string: mapUrlStr) {
                                sharedUrl = url
                            }
                            if sharedText == nil, !name.isEmpty {
                                sharedText = name
                            }
                        }
                    }
                }

                // 2. public.url (Google Maps or Apple Maps web links)
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { (item, _) in
                        defer { group.leave() }
                        if let url = item as? URL {
                            sharedUrl = url
                        } else if let urlStr = item as? String, let url = URL(string: urlStr) {
                            sharedUrl = url
                        }
                    }
                }

                // 3. Plain text
                if provider.hasItemConformingToTypeIdentifier("public.plain-text") ||
                    provider.hasItemConformingToTypeIdentifier("public.text") {
                    let typeId = provider.hasItemConformingToTypeIdentifier("public.plain-text")
                        ? "public.plain-text"
                        : "public.text"
                    group.enter()
                    provider.loadItem(forTypeIdentifier: typeId, options: nil) { (item, _) in
                        defer { group.leave() }
                        if let text = item as? String,
                           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            if sharedText == nil {
                                sharedText = text
                            } else if sharedText?.contains(text) == false {
                                sharedText = "\(sharedText!)\n\(text)"
                            }
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.handleCompletedParsing(url: sharedUrl, text: sharedText)
        }
    }

    private func handleCompletedParsing(url: URL?, text: String?) {
        var payloadParts: [String] = []
        if let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payloadParts.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let url = url {
            let urlString = url.absoluteString
            if text == nil || text?.contains(urlString) == false {
                payloadParts.append(urlString)
            }
        }

        let payload = payloadParts.joined(separator: "\n")
        guard !payload.isEmpty else {
            dismissExtension()
            return
        }

        // 1. Persist pending action to App Group UserDefaults
        saveToAppGroup(payload: payload)

        // 2. Build deep link
        let launchUrl = buildLaunchUrl(payload: payload)

        // 3. Open host app directly
        openHostApp(url: launchUrl)

        // 4. Dismiss extension after allowing SpringBoard time to foreground the host app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.dismissExtension()
        }
    }

    private func saveToAppGroup(payload: String) {
        let defaults = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
        defaults.set("OPEN_LOCATION", forKey: keyPendingAction)
        defaults.set(timestamp, forKey: keyPendingTime)
        defaults.set(payload, forKey: keyPendingData)
        defaults.synchronize()
    }

    private func buildLaunchUrl(payload: String) -> URL {
        var components = URLComponents()
        components.scheme = "feen"
        components.host = "save"
        components.queryItems = [URLQueryItem(name: "data", value: payload)]
        return components.url ?? URL(string: "feen://save")!
    }

    // MARK: - Open Host App

    private func openHostApp(url: URL) {
        // Strategy A: Extension Context open
        if let context = self.extensionContext {
            context.open(url, completionHandler: nil)
        }

        // Strategy B: Call openURL:options:completionHandler: strictly on UIApplication.shared (never UIScene)
        if let appClass = NSClassFromString("UIApplication") as? NSObject.Type,
           let sharedApp = appClass.perform(sel_registerName("sharedApplication"))?.takeUnretainedValue() as? NSObject {
            let openSelector = sel_registerName("openURL:options:completionHandler:")
            if sharedApp.responds(to: openSelector) {
                typealias OpenFunc = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, Any?) -> Void
                if let method = class_getMethodImplementation(type(of: sharedApp), openSelector) {
                    let fn = unsafeBitCast(method, to: OpenFunc.self)
                    fn(sharedApp, openSelector, url as NSURL, [:] as NSDictionary, nil)
                }
            }
        }
    }

    private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
