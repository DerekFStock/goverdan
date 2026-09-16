import SwiftUI
import WebKit

@MainActor
struct VedabaseReaderView: View {
    let initialURL: URL
    let model: AppModel

    @State private var webView = WKWebView()
    @State private var currentURL: URL?
    @State private var pageTitle = "Vedabase"
    @State private var loadError: String?

    init(initialURL: URL, model: AppModel) {
        self.initialURL = initialURL
        self.model = model
        _currentURL = State(initialValue: initialURL)
    }

    private var bookmarkableURL: URL? {
        guard let currentURL, VedabaseBookmarkRecord.isBookmarkable(currentURL) else { return nil }
        return currentURL
    }

    var body: some View {
        VStack(spacing: 0) {
            if let loadError {
                HStack {
                    Text(loadError).font(.caption)
                    Spacer()
                    Button("Retry") { webView.reload() }
                        .accessibilityIdentifier("vedabase.retry")
                }
                .padding(10)
                .background(AppTheme.canvas)
            }

            VedabaseWebView(
                webView: webView,
                initialURL: initialURL,
                currentURL: $currentURL,
                pageTitle: $pageTitle,
                loadError: $loadError
            )
            .accessibilityIdentifier("vedabase.webview")
        }
        .navigationTitle("Vedabase")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let bookmarkableURL {
                        model.toggleVedabaseBookmark(url: bookmarkableURL, title: pageTitle)
                    }
                } label: {
                    Image(systemName: bookmarkableURL.map { model.isVedabaseBookmarked($0) } == true ? "bookmark.fill" : "bookmark")
                }
                .disabled(bookmarkableURL == nil)
                .accessibilityLabel(bookmarkableURL.map { model.isVedabaseBookmarked($0) } == true ? "Remove Bookmark" : "Bookmark Page")
                .accessibilityIdentifier("vedabase.bookmark")
                .accessibilityValue(pageTitle)
            }
        }
    }
}

private struct VedabaseWebView: UIViewRepresentable {
    let webView: WKWebView
    let initialURL: URL
    @Binding var currentURL: URL?
    @Binding var pageTitle: String
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.observePage(webView)
        webView.load(URLRequest(url: initialURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: VedabaseWebView
        private var pageObservations: [NSKeyValueObservation] = []

        init(_ parent: VedabaseWebView) { self.parent = parent }

        func observePage(_ webView: WKWebView) {
            pageObservations = [
                webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                    MainActor.assumeIsolated {
                        if let url = webView.url { self?.parent.currentURL = url }
                    }
                },
                webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                    MainActor.assumeIsolated {
                        if let title = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
                            self?.parent.pageTitle = title
                        }
                    }
                }
            ]
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if url.scheme == "about" || (url.scheme == "https" && ["vedabase.io", "www.vedabase.io"].contains(url.host?.lowercased() ?? "")) {
                decisionHandler(.allow)
            } else {
                if navigationAction.navigationType == .linkActivated,
                   ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updatePageState(webView)
            parent.loadError = nil
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            updatePageState(webView)
        }

        private func updatePageState(_ webView: WKWebView) {
            if let url = webView.url {
                parent.currentURL = url
            }
            let title = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let title, !title.isEmpty {
                parent.pageTitle = title
            } else {
                parent.pageTitle = "Vedabase reading"
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.loadError = "Vedabase could not load. Check your connection."
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loadError = "Vedabase could not load. Check your connection."
        }
    }
}
