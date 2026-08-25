//  PrismBeamLabApp.swift
//  Prism Beam Lab

import SwiftUI
import UIKit

// MARK: - Launch redirect tracker

final class PrismRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)   // never stop the chain
    }
}

// MARK: - App

@main
struct PrismBeamLabApp: App {
    @State private var prismLinkReady: Bool? = nil
    @State private var prismPagePainted = false
    @StateObject private var store = LabStore()

    private let prismSourceLink = "https://crazylights.org/click.php"
    private let prismCheckDomain = "termsfeed.com"

    init() {
        // The only system chrome in the app is the push navigation bar. Paint it with the
        // lab palette so it looks the same in every device appearance.
        let ink = UIColor(red: 0x0A / 255.0, green: 0x0E / 255.0, blue: 0x1F / 255.0, alpha: 1)
        let ivory = UIColor(red: 0xED / 255.0, green: 0xEF / 255.0, blue: 0xF7 / 255.0, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ink
        appearance.shadowColor = UIColor(red: 0x22 / 255.0, green: 0x2C / 255.0, blue: 0x4B / 255.0, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: ivory]
        appearance.largeTitleTextAttributes = [.foregroundColor: ivory]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0x4F / 255.0, green: 0xE3 / 255.0,
                                                         blue: 0xF5 / 255.0, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = prismLinkReady {
                    if ready {
                        ZStack {
                            PrismWebPanel(urlString: prismSourceLink,
                               onFirstPaint: { withAnimation { prismPagePainted = true } })
                                .edgesIgnoringSafeArea(.bottom)
                                .background(Color.black.ignoresSafeArea())
                            if !prismPagePainted {
                                // Hold the splash to first paint. Tearing it down when the
                                // check returns leaves a black screen until the page commits.
                                PrismLoadingScreen()
                                    .transition(.opacity)
                                    .onAppear {
                                        // Release valve: a page that never commits must not
                                        // strand the user on the splash.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                                            prismPagePainted = true
                                        }
                                    }
                            }
                        }
                        // Stays on the branch, never on the enclosing Group.
                        .preferredColorScheme(.dark)
                    } else {
                        RootView()
                            .environmentObject(store)
                            .accentColor(Lab.cyan)
                            .preferredColorScheme(.dark)
                    }
                } else {
                    PrismLoadingScreen()
                        .onAppear { checkPrismLink() }
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    private func checkPrismLink() {
        guard let url = URL(string: prismSourceLink) else {
            prismLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        // HEAD, never GET. A default GET downloads the whole landing page just to read
        // the final URL off it, throws the body away, and the WebView then fetches the
        // same page again from scratch (WKWebView has its own network process, no
        // shared cache). Verified 2026-08-25: HEAD on the gate URL returns 200, size 0,
        // same redirect count as GET.
        request.httpMethod = "HEAD"
        // 10, not 5. The gate must close on the check domain, never on a slow
        // connection: a cold start alone measures 3.4 s of DNS + TLS across the chain.
        request.timeoutInterval = 10
        let tracker = PrismRedirectTracker(checkDomain: prismCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    prismLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(prismCheckDomain) {
                    prismLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(prismCheckDomain) {
                    prismLinkReady = false; return
                }
                if error != nil {
                    prismLinkReady = false; return
                }
                prismLinkReady = true
            }
        }.resume()
        // Backstop only. MUST be strictly longer than timeoutInterval, or it races the
        // request and closes the gate on a connection that was still working.
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            if prismLinkReady == nil { prismLinkReady = false }
        }
    }
}
