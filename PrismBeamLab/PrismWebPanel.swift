//  PrismWebPanel.swift
//  Prism Beam Lab

import SwiftUI
import WebKit

struct PrismWebPanel: UIViewRepresentable {
    let urlString: String
    /// Fired once the page actually commits, so the splash can be held until
    /// there are pixels. Settings/Privacy passes nothing and is unaffected.
    var onFirstPaint: (() -> Void)? = nil

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFirstPaint: (() -> Void)?
        private var fired = false
        // didCommit, not didFinish — didFinish lands seconds after the page is usable.
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { fire() }
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            fire()
        }
        private func fire() { guard !fired else { return }; fired = true; onFirstPaint?() }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        // Required, not optional: the frame extends under the home indicator and this is what
        // insets scrollable content back out of it. Never .never.
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        // Opaque + solid background keeps the safe-area band clean (no white flash).
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        // The branch presenting this runs in the dark scheme so the status-bar glyphs turn
        // white. Pin the page itself back to light so that trait never reaches the site.
        webView.overrideUserInterfaceStyle = .light
        context.coordinator.onFirstPaint = onFirstPaint
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    // MUST stay empty — reloading on a SwiftUI re-render causes an infinite reload loop.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Still never reload here — only refresh the callback reference.
        context.coordinator.onFirstPaint = onFirstPaint
    }
}
