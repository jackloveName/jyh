import Foundation

enum JYHDiagnostics {
    static func log(_ category: String, _ message: @autoclosure () -> String) {
#if DEBUG
        NSLog("[JYH][%@] %@", category, message())
#endif
    }

    static func maskedPrincipal(_ value: String) -> String {
        guard value.count > 4 else { return String(repeating: "*", count: value.count) }
        return String(repeating: "*", count: value.count - 4) + value.suffix(4)
    }

    static func redactedURL(_ url: URL?) -> String {
        guard let url else { return "nil" }
        return url.absoluteString.replacingOccurrences(
            of: #"([?&]token=)[^&]*"#,
            with: "$1***",
            options: .regularExpression
        )
    }

    static func tokenStatus(_ token: String) -> String {
        token.isEmpty ? "empty" : "present(\(token.count))"
    }
}
