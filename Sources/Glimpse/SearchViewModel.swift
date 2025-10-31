import Foundation
import WebKit

@MainActor
final class SearchViewModel: NSObject, ObservableObject {
    @Published var query: String = ""
    @Published private(set) var focusTick: Int = 0
    @Published var isSignedIn: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false

    let webView: WKWebView

    private let historyStore: SearchHistoryStore
    private let engine: SearchEngine = .google
    private var shouldFocusOnLoad: Bool = false

    init(historyStore: SearchHistoryStore) {
        self.historyStore = historyStore

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        super.init()

        webView.navigationDelegate = self
        clearContent()
    }

    func requestFocus() {
        focusTick += 1
    }

    func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = engine.searchURL(for: trimmed) else { return }
        historyStore.record(trimmed)
        webView.load(URLRequest(url: url))
    }

    func clearContent() {
        if let url = URL(string: "https://www.google.com") {
            webView.load(URLRequest(url: url))
        }
    }

    func reset() {
        query = ""
        clearContent()
    }

    func reload() {
        webView.reload()
    }

    func navigateToGoogleSignIn() {
        if let url = URL(string: "https://accounts.google.com") {
            webView.load(URLRequest(url: url))
        }
    }

    func navigateToHome() {
        query = ""  // Clear search query
        shouldFocusOnLoad = true
        if let url = URL(string: "https://www.google.com") {
            webView.load(URLRequest(url: url))
        }
    }

    func focusWebViewSearchField() {
        // Make WebView first responder
        if let window = webView.window {
            window.makeFirstResponder(webView)
        }

        // Then focus on Google's search input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.webView.evaluateJavaScript("""
                const searchInput = document.querySelector('textarea[name="q"], input[name="q"]');
                if (searchInput) {
                    searchInput.focus();
                    searchInput.click();
                }
            """)
        }
    }

    func checkLoginStatus() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            Task { @MainActor in
                let hasGoogleAuth = cookies.contains { cookie in
                    cookie.domain.contains("google.com") &&
                    (cookie.name == "SID" || cookie.name == "SSID" || cookie.name == "HSID")
                }
                self.isSignedIn = hasGoogleAuth
            }
        }
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    private func updateNavigationState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

extension SearchViewModel: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            if shouldFocusOnLoad {
                shouldFocusOnLoad = false
                requestFocus()
            }
            updateNavigationState()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Task { @MainActor in
            updateNavigationState()
        }
    }
}
