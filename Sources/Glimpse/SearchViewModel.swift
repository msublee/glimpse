import Foundation
import WebKit

/// Custom WKWebView that prevents automatic focus stealing
private class NonFocusingWebView: WKWebView {
    var allowsFocus: Bool = false

    override var acceptsFirstResponder: Bool {
        return allowsFocus
    }

    override func becomeFirstResponder() -> Bool {
        guard allowsFocus else {
            return false
        }
        return super.becomeFirstResponder()
    }
}

@MainActor
final class SearchViewModel: NSObject, ObservableObject {
    @Published var query: String = ""
    @Published private(set) var focusTick: Int = 0
    @Published var isSignedIn: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false

    let webView: WKWebView
    private var nonFocusingWebView: NonFocusingWebView? {
        webView as? NonFocusingWebView
    }

    private let historyStore: SearchHistoryStore
    private let engine: SearchEngine = .google
    private var shouldFocusOnLoad: Bool = false
    var onEscapePressed: (() -> Void)?

    init(historyStore: SearchHistoryStore) {
        self.historyStore = historyStore

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let customWebView = NonFocusingWebView(frame: .zero, configuration: configuration)
        customWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView = customWebView

        super.init()

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
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
        // This is now only called for edge cases since we recreate ViewModel
        query = ""
        canGoBack = false
        canGoForward = false
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
        // Temporarily allow WebView to accept focus
        nonFocusingWebView?.allowsFocus = true

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

        // Disable focus after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.nonFocusingWebView?.allowsFocus = false
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
        guard canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard canGoForward else { return }
        webView.goForward()
    }

    private func updateNavigationState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    func setupEscapeKeyHandler() {
        // Inject JavaScript to listen for Escape key in WebView
        let script = WKUserScript(
            source: """
                document.addEventListener('keydown', function(event) {
                    if (event.key === 'Escape' || event.keyCode === 27) {
                        event.preventDefault();
                        event.stopPropagation();
                        window.webkit.messageHandlers.escapePressed.postMessage('escape');
                    }
                }, true);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "escapePressed")
    }
}

extension SearchViewModel: WKScriptMessageHandler {
    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Task { @MainActor in
            if message.name == "escapePressed" {
                self.onEscapePressed?()
            }
        }
    }
}

extension SearchViewModel: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            // Only blur if we're not allowing WebView focus (i.e., user didn't use Cmd+/)
            if let nonFocusing = webView as? NonFocusingWebView, !nonFocusing.allowsFocus {
                _ = try? await webView.evaluateJavaScript("""
                    if (document.activeElement && document.activeElement.tagName !== 'BODY') {
                        document.activeElement.blur();
                    }
                """)
            }

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
