import Foundation

enum AppConfig {
    /// Shared request identity used by login and system configuration requests.
    static let appName = "金瀛花"
    static let h5ConfigurationKey = "JYH_H5_CONFIG"
    static let tempUid = ""

    static let apiBaseURL = URL(string: "https://gateway.tianyuankeji.top")!
    static let ossBaseURL = URL(string: "https://mizhenhl.oss-cn-beijing.aliyuncs.com")!
    static let fallbackH5BaseURL = URL(string: "https://jyh-h5.tianyuankeji.top")!
}
