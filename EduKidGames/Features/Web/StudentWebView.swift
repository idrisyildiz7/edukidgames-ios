import SwiftUI
import WebKit

struct StudentWebViewContainer: View {
    private let startURL = URL(string: AppConstants.loginURL)!
    @State private var logoutRequestID = 0
    @State private var currentURL: URL?

    private var isLoginPage: Bool {
        guard let currentURL else { return true }
        return currentURL.path.hasPrefix("/Account/Login")
    }

    var body: some View {
        ZStack {
            EduKidScreenBackground()
            VStack(spacing: 0) {
                if !isLoginPage {
                    webTopBar
                }
                StudentWebView(
                    url: startURL,
                    logoutRequestID: logoutRequestID,
                    onURLChange: { url in currentURL = url }
                )
            }
        }
    }

    private var webTopBar: some View {
        HStack {
            EduKidLogoHorizontal(height: 32)
            Spacer()
            Button {
                logoutRequestID += 1
            } label: {
                Text("web.logout")
                    .font(EduKidTypography.labelLarge)
                    .foregroundStyle(EduKidColors.orange)
            }
        }
        .padding(.horizontal, EduKidSpacing.screenPadding)
        .padding(.vertical, 10)
        .background(EduKidColors.paper)
    }
}

struct StudentWebView: UIViewRepresentable {
    let url: URL
    let logoutRequestID: Int
    var onURLChange: ((URL?) -> Void)? = nil

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = AppConstants.webViewUserAgent
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.observeAppLifecycle()
        context.coordinator.applyZoomPolicy(for: url, in: webView)
        context.coordinator.startInitialLoad(url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onURLChange = onURLChange
        if context.coordinator.lastHandledLogoutRequestID != logoutRequestID {
            context.coordinator.lastHandledLogoutRequestID = logoutRequestID
            context.coordinator.performLogout(in: webView, startURL: url)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var onURLChange: ((URL?) -> Void)?
        var lastHandledLogoutRequestID = 0
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
            if isLogin {
                webView.scrollView.setZoomScale(1, animated: false)
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
              existing.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
              if (document.body) { document.body.style.zoom = '1'; }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        private func clearWebViewData(of webView: WKWebView, completion: @escaping () -> Void) {
            let dataStore = webView.configuration.websiteDataStore
            dataStore.httpCookieStore.getAllCookies { cookies in
                let group = DispatchGroup()
                for cookie in cookies {
                    group.enter()
                    dataStore.httpCookieStore.delete(cookie) { group.leave() }
                }
                group.notify(queue: .main) {
                    let types = WKWebsiteDataStore.allWebsiteDataTypes()
                    dataStore.fetchDataRecords(ofTypes: types) { records in
                        dataStore.removeData(ofTypes: types, for: records) { completion() }
                    }
                }
            }
        }

        func performLogout(in webView: WKWebView, startURL: URL) {
            WebCookieStore.clear()
            clearWebViewData(of: webView) {
                webView.load(URLRequest(url: startURL, cachePolicy: .reloadIgnoringLocalCacheData))
            }
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
                onURLChange?(url)
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let currentURL = webView.url {
                applyZoomPolicy(for: currentURL, in: webView)
                if isLoginPage(currentURL) { enforceLoginViewport(in: webView) }
                onURLChange?(currentURL)
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
