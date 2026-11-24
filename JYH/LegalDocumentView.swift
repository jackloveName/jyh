import SwiftUI
import WebKit

struct LegalDocumentView: View {
    let type: LegalDocumentType

    @Environment(\.dismiss) private var dismiss
    @State private var html = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reloadID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                if isLoading {
                    ProgressView("协议加载中")
                        .tint(JYColor.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("协议加载失败", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("重新加载") {
                            reloadID = UUID()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(JYColor.primary)
                    }
                } else {
                    LegalHTMLWebView(html: wrappedHTML)
                        .id(reloadID)
                }
            }
            .background(JYColor.canvas)
        }
        .background(JYColor.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task(id: reloadID) {
            await loadDocument()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image("figma-back")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 24, height: 20)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("返回")

            Text(type.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Color.white)
    }

    private var wrappedHTML: String {
        if html.range(of: "<html", options: .caseInsensitive) != nil {
            return html
        }
        return """
        <!doctype html>
        <html lang="zh-CN">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>
        :root { color-scheme: light; }
        * { box-sizing: border-box; }
        body {
          margin: 0;
          padding: 18px 18px 48px;
          background: #F6F8FB;
          color: #344054;
          font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif;
          font-size: 15px;
          line-height: 1.85;
          word-break: break-word;
        }
        h1 { display: none; }
        h2 {
          margin: 30px 0 12px;
          color: #18253C;
          font-size: 18px;
          line-height: 1.45;
        }
        h3 {
          margin: 22px 0 8px;
          color: #18253C;
          font-size: 16px;
          line-height: 1.5;
        }
        p { margin: 10px 0; }
        ol, ul { margin: 10px 0; padding-left: 24px; }
        li { margin: 7px 0; }
        strong { color: #18253C; }
        .enterprise-list {
          margin: 8px 0 14px;
          padding: 12px 14px;
          border-radius: 10px;
          background: #FFFFFF;
          color: #18253C;
        }
        a { color: #086CF5; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }

    @MainActor
    private func loadDocument() async {
        isLoading = true
        errorMessage = nil
        do {
            html = try await APIClient.shared.legalDocument(type: type)
            JYHDiagnostics.log(
                "协议",
                "读取成功 type=\(type.rawValue) length=\(html.count)"
            )
        } catch {
            html = ""
            errorMessage = error.localizedDescription
            JYHDiagnostics.log(
                "协议",
                "读取失败 type=\(type.rawValue) error=\(error.localizedDescription)"
            )
        }
        isLoading = false
    }
}

private struct LegalHTMLWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url == nil else { return }
        webView.loadHTMLString(html, baseURL: nil)
    }
}
