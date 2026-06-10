import SwiftUI
import WebKit

/// Tam ekran WebView — native chrome yok; web paneli doğrudan uygulama gibi görünür.
struct StudentWebViewContainer: View {
    var deepLinkRoute: String? = nil

    private var startURL: URL {
        if let route = deepLinkRoute, route.hasPrefix("/"),
           let url = URL(string: AppConstants.apiBaseURL + route) {
            return url
        }
        return URL(string: AppConstants.studentHomeURL)!
    }
    @State private var isLoading = true

    var body: some View {
        ZStack {
            StudentWebView(url: startURL, isLoading: $isLoading)
                .ignoresSafeArea()

            if isLoading {
                WebViewLoadingOverlay()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.32), value: isLoading)
    }
}

private struct WebViewLoadingOverlay: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [EduKidColors.gradientTop, EduKidColors.cream, EduKidColors.gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                EduKidLogoHorizontal(height: 76, maxWidth: 300, showShadow: true)
                    .scaleEffect(pulse ? 1.02 : 0.98)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                WebViewLoadingDots()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear { pulse = true }
    }
}

private struct WebViewLoadingDots: View {
    private let colors: [Color] = [
        EduKidColors.orange,
        Color(red: 0.18, green: 0.77, blue: 0.71),
        Color(red: 1.0, green: 0.45, blue: 0.55)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = sin(t * 4 + Double(index) * 0.85)
                    Circle()
                        .fill(colors[index])
                        .frame(width: 11, height: 11)
                        .offset(y: CGFloat(phase) * 5)
                        .opacity(0.55 + (phase + 1) * 0.225)
                }
            }
        }
    }
}

struct StudentWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

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

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: StudentWebView
        weak var webView: WKWebView?
        private var didStartInitialLoad = false
        private var lifecycleObserved = false
        private var loadingStartedAt = Date()
        private var pendingLogout = false

        init(parent: StudentWebView) {
            self.parent = parent
        }

        private static let externalSchemes: Set<String> = ["tel", "telprompt", "sms", "mailto", "facetime"]

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        private func isLoginPage(_ url: URL) -> Bool {
            url.path.hasPrefix("/Account/Login")
        }

        private func isLogoutPage(_ url: URL) -> Bool {
            url.path.hasPrefix(AppConstants.logoutPathPrefix)
        }

        private func handleLogout(in webView: WKWebView) {
            pendingLogout = false
            WebCookieStore.clearAll(in: webView.configuration.websiteDataStore.httpCookieStore)
        }

        func startInitialLoad(_ url: URL, in webView: WKWebView) {
            guard !didStartInitialLoad else { return }
            didStartInitialLoad = true
            setLoading(true)
            WebCookieStore.restore(into: webView.configuration.websiteDataStore.httpCookieStore) {
                webView.load(URLRequest(url: url))
            }
        }

        private func setLoading(_ loading: Bool) {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.32)) {
                    self.parent.isLoading = loading
                }
            }
        }

        private func beginLoading() {
            loadingStartedAt = Date()
            setLoading(true)
        }

        private func endLoading() {
            let minimum: TimeInterval = 0.45
            let elapsed = Date().timeIntervalSince(loadingStartedAt)
            let delay = max(0, minimum - elapsed)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.setLoading(false)
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
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(persistCookies),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(persistCookies),
                name: UIApplication.willTerminateNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(refreshLoginLayout),
                name: UIResponder.keyboardWillChangeFrameNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(refreshLoginLayout),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
        }

        @objc private func refreshLoginLayout() {
            guard let webView, let url = webView.url, isLoginPage(url) else { return }
            webView.scrollView.setContentOffset(.zero, animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                webView.scrollView.setContentOffset(.zero, animated: false)
                webView.evaluateJavaScript(
                    "window.EduKidAuthApp && window.EduKidAuthApp.refreshLayout && window.EduKidAuthApp.refreshLayout();",
                    completionHandler: nil
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                webView.scrollView.setContentOffset(.zero, animated: false)
                webView.evaluateJavaScript(
                    "window.EduKidAuthApp && window.EduKidAuthApp.refreshLayout && window.EduKidAuthApp.refreshLayout();",
                    completionHandler: nil
                )
            }
        }

        @objc private func persistCookies() {
            guard let webView else { return }
            var backgroundTask: UIBackgroundTaskIdentifier = .invalid
            backgroundTask = UIApplication.shared.beginBackgroundTask {
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }
            WebCookieStore.persist(from: webView.configuration.websiteDataStore.httpCookieStore) {
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }
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
            webView.scrollView.pinchGestureRecognizer?.isEnabled = false
            webView.scrollView.minimumZoomScale = 1
            webView.scrollView.maximumZoomScale = 1
            webView.scrollView.isScrollEnabled = !isLogin
            webView.scrollView.bounces = !isLogin
            webView.scrollView.alwaysBounceVertical = !isLogin
            webView.scrollView.setZoomScale(1, animated: false)
            if isLogin {
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
              existing.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover, interactive-widget=resizes-visual';
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
            if (window.EduKidAuthApp) {
              if (window.EduKidAuthApp.applyNativeSafeArea) {
                window.EduKidAuthApp.applyNativeSafeArea(\(top), \(bottom));
              }
              if (window.EduKidAuthApp.resetStableHeight) window.EduKidAuthApp.resetStableHeight();
              if (window.EduKidAuthApp.refreshLayout) window.EduKidAuthApp.refreshLayout();
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
                if isLogoutPage(url) {
                    pendingLogout = true
                }
                applyZoomPolicy(for: url, in: webView)
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            beginLoading()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let currentURL = webView.url {
                applyZoomPolicy(for: currentURL, in: webView)
                if isLoginPage(currentURL) {
                    enforceLoginViewport(in: webView)
                    injectAuthSafeArea(in: webView)
                    if pendingLogout {
                        handleLogout(in: webView)
                    }
                } else if isLogoutPage(currentURL) {
                    handleLogout(in: webView)
                }
            }
            WebCookieStore.persist(from: webView.configuration.websiteDataStore.httpCookieStore) {
                // completion: persist is async; overlay already handled in endLoading()
            }
            endLoading()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            endLoading()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled { return }
            endLoading()
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
