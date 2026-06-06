import SwiftUI
import WebKit

/// Tam ekran WebView — native chrome yok; web paneli doğrudan uygulama gibi görünür.
struct StudentWebViewContainer: View {
    private let startURL = URL(string: AppConstants.loginURL)!

    var body: some View {
        StudentWebView(url: startURL)
            .ignoresSafeArea()
    }
}

struct StudentWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = AppConstants.webViewUserAgent
        webView.isOpaque = false
        webView.backgroundColor = UIColor(EduKidColors.cream)
        webView.scrollView.backgroundColor = UIColor(EduKidColors.cream)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.observeAppLifecycle()
        context.coordinator.applyZoomPolicy(for: url, in: webView)
        context.coordinator.startInitialLoad(url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?
        private var didStartInitialLoad = false
        private var lifecycleObserved = false

        private static let externalSchemes: Set<String> = ["tel", "telprompt", "sms", "mailto", "facetime"]

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        private func isLoginPage(_ url: URL) -> Bool {
            url.path.hasPrefix("/Account/Login")
        }

        func startInitialLoad(_ url: URL, in webView: WKWebView) {
            guard !didStartInitialLoad else { return }
            didStartInitialLoad = true
            WebCookieStore.restore(into: webView.configuration.websiteDataStore.httpCookieStore) {
                webView.load(URLRequest(url: url))
            }
        }

        func observeAppLifecycle() {
            guard !lifecycleObserved else { return }
            lifecycleObserved = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(persistCookies),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }

        @objc private func persistCookies() {
            guard let webView else { return }
            WebCookieStore.persist(from: webView.configuration.websiteDataStore.httpCookieStore)
        }

        @discardableResult
        private func openExternalIfNeeded(_ url: URL?) -> Bool {
            guard let url, let scheme = url.scheme?.lowercased(),
                  Self.externalSchemes.contains(scheme) else { return false }
            UIApplication.shared.open(url)
            return true
        }

        func applyZoomPolicy(for url: URL, in webView: WKWebView) {
            let isLogin = isLoginPage(url)
            webView.scrollView.pinchGestureRecognizer?.isEnabled = !isLogin
            webView.scrollView.minimumZoomScale = isLogin ? 1 : 0.5
            webView.scrollView.maximumZoomScale = isLogin ? 1 : 3
            webView.scrollView.isScrollEnabled = !isLogin
            webView.scrollView.bounces = !isLogin
            webView.scrollView.alwaysBounceVertical = !isLogin
            if isLogin {
                webView.scrollView.setZoomScale(1, animated: false)
                webView.scrollView.contentOffset = .zero
            }
        }

        private func enforceLoginViewport(in webView: WKWebView) {
            let script = """
            (function() {
              var existing = document.querySelector('meta[name="viewport"]');
              if (!existing) {
                existing = document.createElement('meta');
                existing.name = 'viewport';
                document.head.appendChild(existing);
              }
              existing.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
              if (document.body) { document.body.style.zoom = '1'; }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        /// WKWebView'da env(safe-area-inset-*) 0 dönebildiği için login ekranına native inset enjekte eder.
        private func injectAuthSafeArea(in webView: WKWebView) {
            let insets = webView.window?.safeAreaInsets
                ?? webView.superview?.safeAreaInsets
                ?? .zero
            let top = max(insets.top, 0)
            let bottom = max(insets.bottom, 0)
            let script = """
            if (window.EduKidAuthApp && window.EduKidAuthApp.applyNativeSafeArea) {
              window.EduKidAuthApp.applyNativeSafeArea(\(top), \(bottom));
            } else {
              document.documentElement.dataset.authSafeNative = '1';
              document.documentElement.style.setProperty('--auth-safe-top', '\(top)px');
              document.documentElement.style.setProperty('--auth-safe-bottom', '\(bottom)px');
            }
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if openExternalIfNeeded(navigationAction.request.url) {
                decisionHandler(.cancel)
                return
            }
            if let url = navigationAction.request.url {
                applyZoomPolicy(for: url, in: webView)
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let currentURL = webView.url {
                applyZoomPolicy(for: currentURL, in: webView)
                if isLoginPage(currentURL) {
                    enforceLoginViewport(in: webView)
                    injectAuthSafeArea(in: webView)
                }
            }
            WebCookieStore.persist(from: webView.configuration.websiteDataStore.httpCookieStore)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            let url = navigationAction.request.url
            if !openExternalIfNeeded(url), navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
