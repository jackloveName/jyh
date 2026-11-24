import Foundation

struct TokenBundle: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: Double?
}

struct UserProfile: Equatable {
    var id: String = ""
    var nickName: String = "\(AppConfig.appName)用户"
    var mobile: String = ""
    var avatar: String = ""
    var borrowFlag: Int = 0
    var realNameVerified: Bool = false
    var memberLevel: String = "普通用户"

    static let guest = UserProfile()

    var maskedMobile: String {
        guard mobile.count >= 7 else { return mobile.isEmpty ? "登录后同步账户信息" : mobile }
        return mobile.replacingCharacters(
            in: mobile.index(mobile.startIndex, offsetBy: 3)..<mobile.index(mobile.startIndex, offsetBy: 7),
            with: "****"
        )
    }

    var initials: String {
        let trimmed = nickName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "金" : String(trimmed.prefix(1))
    }
}

struct LoanProduct: Identifiable, Equatable {
    var id: String
    var title: String
    var subtitle: String
    var maximumAmount: Double
    var annualRate: String
}

struct LoanOverview: Equatable {
    var estimatedAmount: Double = 8_000
    var availableAmount: Double = 8_000
    var minimumRate: Double = 7.2
    var maximumRate: Double = 24.0
    var products: [LoanProduct] = [
        .init(id: "welcome", title: "\(AppConfig.appName)借款服务", subtitle: "额度、期限及利率以审批和合同为准", maximumAmount: 8_000, annualRate: "以合同约定为准")
    ]
}

struct RepaymentSummary: Equatable {
    var outstandingAmount: Double = 710.24
    var dueDate: String = Self.simulatedDueDate
    var status: String = "待还款"
    var loanOrderCount: Int = 1
    var shopOrderCount: Int = 0
    var currentPeriod: Int = 5
    var principal: Double = 7_600
    var termMonths: Int = 12
    var annualRate: Double = 24
    var totalInterest: Double = 922.89

    private static var simulatedDueDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct KYCStep: Identifiable, Equatable {
    var id: String
    var collectType: String
    var name: String
    var status: String
}

struct StoredLoanApplication: Equatable {
    var applicationId: String
    var status: String
    var principal: Double
    var termMonths: Int
    var productName: String
    var submittedAt: Date?
    var reviewDeadlineAt: Date?

    var isReviewing: Bool { status == "reviewing" }
    var isRejected: Bool { status == "rejected" }
    var isApproved: Bool { status == "approved" || status == "disbursed" }
}

struct FeedbackRecord: Identifiable, Equatable {
    var id: String
    var feedbackId: String
    var categoryId: String
    var categoryName: String
    var content: String
    var contactMobile: String
    var allowContact: Bool
    var attachmentPaths: [String]
    var status: String
    var reply: String
    var createdAt: Date?

    var statusText: String {
        switch status {
        case "processing": return "处理中"
        case "replied": return "已回复"
        case "closed": return "已完成"
        default: return "已提交，待处理"
        }
    }
}

enum KYCNextStep: Equatable {
    case identityCard
    case faceRecognition
    case profileInformation
    case loanReady
    case unavailable

    var actionTitle: String {
        switch self {
        case .identityCard: return "去实名认证"
        case .faceRecognition: return "继续人脸识别"
        case .profileInformation: return "完善申请资料"
        case .loanReady: return "立即申请"
        case .unavailable: return "请稍后重试"
        }
    }
}

struct AppRemoteConfiguration: Equatable {
    var h5DownloadUrl: String
    var serviceLink: String
    var serviceSwitch: Bool
    var h5Routes: H5RoutePaths?

    var h5BaseURL: URL? {
        let value = h5DownloadUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !value.isEmpty,
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return url
    }
}

enum LoginMethod: String, CaseIterable {
    case code = "验证码登录"
    case password = "密码登录"
}

enum AppRoute: Hashable {
    case loanFlow
    case repaymentHistory
    case support
    case helpCenter
    case lenders
    case about
    case safety
    case settings
    case feedback
    case userAgreement
    case privacyPolicy
    case changePassword
    case profileEdit
    case h5Identity
    case h5Face
    case h5Profile
    case h5LoanResult
    case h5Bill
    case applicationConditions
    case loanProcessGuide
    case quotaGuide
    case repaymentGuide
}

enum LegalDocumentType: String, Identifiable, Hashable {
    case privacyPolicy
    case userAgreement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: return "隐私政策"
        case .userAgreement: return "用户协议"
        }
    }

    var configurationKey: String {
        switch self {
        case .privacyPolicy: return JYLegal.privacyProtocolKey
        case .userAgreement: return JYLegal.registerProtocolKey
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(code: String, message: String)
    case unauthorized
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效"
        case .invalidResponse:
            return "服务器返回了无法识别的数据"
        case let .server(_, message):
            return message.isEmpty ? "服务暂时不可用" : message
        case .unauthorized:
            return "登录状态已失效，请重新登录"
        case let .transport(message):
            return message.isEmpty ? "网络连接失败" : message
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func string(_ key: String, fallback: String = "") -> String {
        if let value = self[key] as? String { return value }
        if let value = self[key] as? NSNumber { return value.stringValue }
        return fallback
    }

    func double(_ key: String, fallback: Double = 0) -> Double {
        if let value = self[key] as? Double { return value }
        if let value = self[key] as? Int { return Double(value) }
        if let value = self[key] as? NSNumber { return value.doubleValue }
        if let value = self[key] as? String { return Double(value) ?? fallback }
        return fallback
    }

    func int(_ key: String, fallback: Int = 0) -> Int {
        if let value = self[key] as? Int { return value }
        if let value = self[key] as? NSNumber { return value.intValue }
        if let value = self[key] as? String { return Int(value) ?? fallback }
        return fallback
    }

    func bool(_ key: String, fallback: Bool = false) -> Bool {
        if let value = self[key] as? Bool { return value }
        if let value = self[key] as? NSNumber { return value.boolValue }
        if let value = self[key] as? String {
            return ["1", "true", "yes"].contains(value.lowercased())
        }
        return fallback
    }
}
