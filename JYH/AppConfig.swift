import Foundation

enum AppConfig {
    /// Shared request identity used by login and system configuration requests.
    static let appName = "金瀛花"
    static let h5ConfigurationKey = "JYH_H5_CONFIG"
    static let tempUid = ""

    static let apiBaseURL = URL(string: "https://mbhl.makcabxa02y.icu")!
    static let ossBaseURL = URL(string: "https://mizhenhl.oss-cn-beijing.aliyuncs.com")!

    /// Used only when the remote h5DownloadUrl has not been loaded yet.
    static let fallbackH5BaseURL = URL(string: "https://mbhl.makcabxa02y.icu")!

#if DEBUG
    static let localH5PreviewURL = URL(string: "http://127.0.0.1:8081/?preview=jinyinghua")!
#endif
}
