import UIKit

enum MapsLauncher {
    static func openDirections(latitude: Double, longitude: Double, label: String?) {
        let google = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving")
        let apple = URL(string: "https://maps.apple.com/?daddr=\(latitude),\(longitude)&dirflg=d")
        let web = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)")
        
        if let apple {
            UIApplication.shared.open(apple)
            return
        }
        
        if let google, UIApplication.shared.canOpenURL(google) {
            UIApplication.shared.open(google)
            return
        }
      
        if let web {
            UIApplication.shared.open(web)
        }
    }

    static func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    static func openMail(_ email: String) {
        openURL("mailto:\(email)")
    }

    static func openStoreReview() {
        openURL(AppLinks.appStore)
    }
}

enum ShareService {
    static func shareText(_ text: String, subject: String) {
        present([text])
    }

    static func shareSpot(_ spot: Spot, l10n: L10n) {
        shareText(SpotLinkBuilder.buildSingle(spot, l10n: l10n), subject: spot.isCar ? l10n.t("myCar") : spot.name)
    }

    static func shareAll(_ spots: [Spot], l10n: L10n) {
        let text = SpotLinkBuilder.buildAll(spots, l10n: l10n)
        guard !text.isEmpty else { return }
        shareText(text, subject: l10n.t("shareSubject"))
    }

    static func shareCSV(_ spots: [Spot], l10n: L10n) {
        let csv = SpotsCsvBuilder.build(spots, l10n: l10n)
        guard !csv.isEmpty else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dalely_spots.csv")
        try? ("\u{FEFF}" + csv).data(using: .utf8)?.write(to: url)
        present([url])
    }

    private static func present(_ items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController ?? scene.windows.first?.rootViewController else { return }
        var presenter = root
        while let shown = presenter.presentedViewController { presenter = shown }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = presenter.view
            pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY - 40, width: 1, height: 1)
        }
        presenter.present(vc, animated: true)
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
