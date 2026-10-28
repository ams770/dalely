import SwiftUI
import WebKit

struct LottieAnimationView: UIViewRepresentable {
    let filename: String
    var loop: Bool = true
    var speed: Double = 1.0

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false

        loadAnimation(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op for continuous animation
    }

    private func loadAnimation(into webView: WKWebView) {
        guard let lottieJsUrl = Bundle.main.url(forResource: "lottie", withExtension: "min.js"),
              let lottieJs = try? String(contentsOf: lottieJsUrl, encoding: .utf8),
              let jsonUrl = Bundle.main.url(forResource: filename, withExtension: "json"),
              let jsonData = try? Data(contentsOf: jsonUrl),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body, html { width: 100%; height: 100%; overflow: hidden; background: transparent; display: flex; align-items: center; justify-content: center; }
          #anim { width: 100%; height: 100%; }
        </style>
        <script>\(lottieJs)</script>
        </head>
        <body>
        <div id="anim"></div>
        <script>
          const anim = lottie.loadAnimation({
            container: document.getElementById('anim'),
            renderer: 'svg',
            loop: \(loop ? "true" : "false"),
            autoplay: true,
            animationData: \(jsonString)
          });
          anim.setSpeed(\(speed));
        </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
}
