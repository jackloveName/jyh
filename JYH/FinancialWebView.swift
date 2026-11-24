import SwiftUI
import WebKit

struct FinancialWebView: View {
    let title: String
    let url: URL?
    var showsNativeBackButton = false

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var reloadID = UUID()

    var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView {
                    Label("页面暂时无法加载", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(loadError)
                } actions: {
                    Button("重新加载") {
                        self.loadError = nil
                        isLoading = true
                        reloadID = UUID()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(JYColor.primary)
                }
            } else if let url {
                ZStack(alignment: .top) {
                    WebView(
                        title: title,
                        url: url,
                        isLoading: $isLoading,
                        loadError: $loadError,
                        onClose: {
                            dismiss()
                            Task {
                                await store.refreshAll()
                            }
                        },
                        onLoanSubmitted: {
                            Task {
                                await store.loadStoredLoanApplicationIfNeeded()
                            }
                        },
                        onAuthExpired: { reason in
                            dismiss()
                            store.handleH5AuthExpired(reason: reason)
                        }
                    )
                    .id(reloadID)
                    if isLoading {
                        ProgressView()
                            .tint(JYColor.primary)
                            .padding(.top, 8)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("请先登录", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("登录后可继续查看资金服务")
                }
            }
        }
        .navigationTitle(title)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) {
            if showsNativeBackButton {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Color.white
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(JYColor.action)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                .accessibilityLabel("返回")
                .zIndex(20)
            }
        }
    }
}

private struct WebView: UIViewRepresentable {
    let title: String
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    let onClose: () -> Void
    let onLoanSubmitted: () -> Void
    let onAuthExpired: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isLoading: $isLoading,
            loadError: $loadError,
            onClose: onClose,
            onLoanSubmitted: onLoanSubmitted,
            onAuthExpired: onAuthExpired
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(context.coordinator, name: "jinyinghuaClose")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        context.coordinator.load(url, title: title, in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.load(url, title: title, in: uiView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        @Binding private var isLoading: Bool
        @Binding private var loadError: String?
        private let onClose: () -> Void
        private let onLoanSubmitted: () -> Void
        private let onAuthExpired: (String) -> Void
        private var requestedURL: URL?

        init(
            isLoading: Binding<Bool>,
            loadError: Binding<String?>,
            onClose: @escaping () -> Void,
            onLoanSubmitted: @escaping () -> Void,
            onAuthExpired: @escaping (String) -> Void
        ) {
            _isLoading = isLoading
            _loadError = loadError
            self.onClose = onClose
            self.onLoanSubmitted = onLoanSubmitted
            self.onAuthExpired = onAuthExpired
        }

        func load(_ targetURL: URL, title: String, in webView: WKWebView) {
            guard requestedURL != targetURL else { return }
            requestedURL = targetURL
            DispatchQueue.main.async { [weak self] in
                self?.loadError = nil
                self?.isLoading = true
            }
            JYHDiagnostics.log(
                "H5",
                "开始加载 title=\(title) url=\(JYHDiagnostics.redactedURL(targetURL))"
            )
            webView.stopLoading()
            webView.load(URLRequest(url: targetURL))
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "jinyinghuaClose" else { return }
            let payload = message.body as? [String: Any]
            let event = payload?["event"] as? String ?? "close"
            let reason = payload?["reason"] as? String ?? ""
            JYHDiagnostics.log("H5", "收到 bridge event=\(event) reason=\(reason)")

            switch event {
            case "authExpired":
                onAuthExpired(reason.isEmpty ? "unknown" : reason)
            case "loanSubmitted":
                onLoanSubmitted()
            case "back", "close":
                onClose()
            default:
                JYHDiagnostics.log("H5", "忽略未知 bridge 事件 event=\(event)")
            }
        }

        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            JYHDiagnostics.log(
                "H5",
                "媒体采集授权 host=\(origin.host) type=\(type.rawValue)"
            )
            switch type {
            case .camera:
                decisionHandler(.grant)
            case .cameraAndMicrophone:
                decisionHandler(.deny)
            case .microphone:
                decisionHandler(.deny)
            @unknown default:
                decisionHandler(.deny)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            loadError = nil
            JYHDiagnostics.log(
                "H5",
                "加载完成 url=\(JYHDiagnostics.redactedURL(webView.url)) title=\(webView.title ?? "nil")"
            )
            logCurrentPage(in: webView, phase: "加载完成时")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak webView] in
                guard let self, let webView else { return }
                self.logCurrentPage(in: webView, phase: "1.5 秒后")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self, weak webView] in
                guard let self, let webView else { return }
                self.logCurrentPage(in: webView, phase: "4 秒后")
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = "请检查网络连接后重试。"
            JYHDiagnostics.log(
                "H5",
                "加载失败 url=\(JYHDiagnostics.redactedURL(webView.url)) error=\(error.localizedDescription)"
            )
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = "请检查网络连接后重试。"
            JYHDiagnostics.log(
                "H5",
                "预加载失败 url=\(JYHDiagnostics.redactedURL(webView.url)) error=\(error.localizedDescription)"
            )
        }

        private func logCurrentPage(in webView: WKWebView, phase: String) {
            webView.evaluateJavaScript(
                "({ href: window.location.href, title: document.title, body: (document.body && document.body.innerText || '').slice(0, 120) })"
            ) { value, error in
                if let error {
                    JYHDiagnostics.log(
                        "H5",
                        "\(phase)读取页面失败 error=\(error.localizedDescription)"
                    )
                    return
                }
                var state = value as? [String: Any] ?? ["value": String(describing: value)]
                if let href = state["href"] as? String {
                    state["href"] = JYHDiagnostics.redactedURL(URL(string: href))
                }
                JYHDiagnostics.log("H5", "\(phase) state=\(state)")
            }
        }
    }
}
