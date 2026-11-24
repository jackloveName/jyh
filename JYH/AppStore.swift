import Combine
import Foundation
import UIKit

@MainActor
final class AppStore: ObservableObject {
    @Published var hasEnteredApp = false
    @Published var showLogin = false
    @Published var isLoggedIn = false
    @Published var isBusy = false
    @Published var toastMessage: String?
    @Published var user: UserProfile = .guest
    @Published var overview: LoanOverview = .init()
    @Published var repayment: RepaymentSummary = .init()
    @Published var kycSteps: [KYCStep] = []
    @Published var storedLoanApplication: StoredLoanApplication?
    @Published var lenderInstitutions: [LenderInstitution] = []
    @Published private(set) var avatarRevision = 0
    @Published var remoteConfiguration: AppRemoteConfiguration?
    @Published private(set) var h5DownloadUrl = ""
    @Published private(set) var h5Routes: H5RoutePaths
    @Published var selectedTab: MainTab = .home

    private let api = APIClient.shared
    private let defaults = UserDefaults.standard
    private let tokenKey = "jinyinghua.accessToken"
    private let h5DownloadUrlKey = "jinyinghua.h5DownloadUrl"
    private let h5RoutesKey = "jinyinghua.h5Routes"
    private var toastTask: Task<Void, Never>?

    init() {
        h5Routes = H5RoutePaths(
            dictionary: defaults.dictionary(forKey: h5RoutesKey) ?? [:]
        )
        h5DownloadUrl = defaults.string(forKey: h5DownloadUrlKey) ?? ""
        if let token = defaults.string(forKey: tokenKey), !token.isEmpty {
            isLoggedIn = true
            hasEnteredApp = true
        }
        selectedTab = .home
        JYHDiagnostics.log(
            "启动",
            "恢复状态 token=\(JYHDiagnostics.tokenStatus(token)) isLoggedIn=\(isLoggedIn) hasEnteredApp=\(hasEnteredApp) selectedTab=\(selectedTab.rawValue) h5BaseURL=\(JYHDiagnostics.redactedURL(h5BaseURL))"
        )
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kyc-complete") {
            isLoggedIn = true
            hasEnteredApp = true
            user.realNameVerified = true
        }
        if let flagIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--screen"),
           ProcessInfo.processInfo.arguments.indices.contains(flagIndex + 1) {
            let screen = ProcessInfo.processInfo.arguments[flagIndex + 1]
            switch screen {
            case "home":
                selectedTab = .home
            case "profile":
                selectedTab = .profile
            default:
                selectedTab = MainTab(rawValue: screen) ?? selectedTab
            }
            hasEnteredApp = true
        }
#endif
    }

    var token: String { defaults.string(forKey: tokenKey) ?? "" }
    private var usesLocalH5PreviewIfDebug: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("--h5-local")
#else
        false
#endif
    }
    private var h5AccessToken: String {
#if DEBUG
        if usesLocalH5PreviewIfDebug && token.isEmpty {
            return "preview"
        }
#endif
        return token
    }
    var hasRejectedBorrowApplication: Bool {
        isLoggedIn &&
        user.borrowFlag == 0 &&
        storedLoanApplication?.isRejected == true
    }
    var currentLenderInstitution: LenderInstitution? {
        lenderInstitutions.first
    }
    var providerDisclosure: String? {
        guard let name = currentLenderInstitution?.name else { return nil }
        return "合作机构：\(name)"
    }
    var quotaNeedsEvaluation: Bool {
        isLoggedIn && overview.estimatedAmount <= 0
    }
    var displayEstimatedQuota: Double {
        guard isLoggedIn else { return 8_000 }
        let estimate = overview.estimatedAmount
        if estimate > 0 {
            return min(estimate, 8_000)
        }
        let available = overview.availableAmount
        return available > 0 ? min(available, 8_000) : 8_000
    }
    var quotaReferenceLabel: String {
        if hasRejectedBorrowApplication { return "本次申请结果" }
        return quotaNeedsEvaluation ? "最高可借额度参考（元）" : "可借额度参考（元）"
    }
    var quotaStatusText: String {
        if hasRejectedBorrowApplication { return "审核已完成" }
        if !isLoggedIn { return "登录后评估" }
        return quotaNeedsEvaluation ? "额度待评估" : "额度已更新"
    }
    var quotaDisplayText: String {
        hasRejectedBorrowApplication ? "暂不可借" : displayEstimatedQuota.amountString
    }
    var maskedQuotaText: String {
        guard !hasRejectedBorrowApplication else { return quotaDisplayText }
        let digits = displayEstimatedQuota.amountString.filter(\.isNumber)
        let visibleDigits = String(digits.prefix(2))
        return "\(visibleDigits.count == 2 ? visibleDigits : "00")**"
    }
    var quotaDescriptionText: String {
        if hasRejectedBorrowApplication {
            return "本次申请结果已更新，请留意后续服务信息"
        }
        return quotaNeedsEvaluation
            ? "完成认证后更新额度评估结果"
            : "额度、期限及费用以审批和合同为准"
    }
    var quotaGuideSubtitle: String {
        hasRejectedBorrowApplication
            ? "本次借款申请结果已更新。"
            : "当前额度来自认证后的服务端查询结果。"
    }
    var isRealNameVerified: Bool { user.realNameVerified }
    var kycNextStep: KYCNextStep {
        guard !kycSteps.isEmpty else {
            return isRealNameVerified ? .loanReady : .identityCard
        }

        guard let pending = kycSteps.first(where: { $0.status != "2" }) else {
            return .loanReady
        }

        switch pending.collectType {
        case "idcard":
            return .identityCard
        case "face":
            return .faceRecognition
        case "basic":
            return .profileInformation
        default:
            return .unavailable
        }
    }

    var kycActionRoute: AppRoute {
        switch kycNextStep {
        case .identityCard:
            return .h5Identity
        case .faceRecognition:
            return .h5Face
        case .profileInformation:
            return .h5Profile
        case .loanReady:
            return .loanFlow
        case .unavailable:
            return .h5Identity
        }
    }

    var h5BaseURL: URL {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--h5-local") {
            return AppConfig.localH5PreviewURL
        }
#endif
        return AppRemoteConfiguration(
            h5DownloadUrl: h5DownloadUrl,
            serviceLink: "",
            serviceSwitch: false,
            h5Routes: nil
        ).h5BaseURL ?? AppConfig.fallbackH5BaseURL
    }

    var loanFlowURL: URL? {
        guard isLoggedIn || (usesLocalH5PreviewIfDebug) else { return nil }
        return api.loanFlowURL(
            baseURL: h5BaseURL,
            token: h5AccessToken,
            routes: h5Routes
        )
    }

    var repaymentFlowURL: URL? {
        guard isLoggedIn || (usesLocalH5PreviewIfDebug) else { return nil }
        return api.repaymentFlowURL(
            baseURL: h5BaseURL,
            token: h5AccessToken,
            routes: h5Routes
        )
    }

    var loanReviewDetailURL: URL? {
        h5URL(for: .loanResult)
    }

    var customerServiceURL: URL? {
        h5URL(for: .customerService)
    }

    var identityCardURL: URL? { h5URL(for: .identityCard) }
    var faceRecognitionURL: URL? { h5URL(for: .faceRecognition) }
    var profileInformationURL: URL? { h5URL(for: .profileInformation) }

    func h5URL(for route: H5FlowRoute) -> URL? {
        guard isLoggedIn || (usesLocalH5PreviewIfDebug) else { return nil }
        return H5URLBuilder.url(
            baseURL: h5BaseURL,
            route: route,
            token: h5AccessToken,
            routes: h5Routes
        )
    }

    func h5PreviewURL(for route: H5FlowRoute) -> URL? {
        guard var components = URLComponents(url: h5BaseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "preview" }
        items.append(URLQueryItem(name: "preview", value: "jinyinghua"))
        components.queryItems = items
        guard let baseURL = components.url else { return nil }
        return H5URLBuilder.url(
            baseURL: baseURL,
            route: route,
            token: "preview",
            routes: h5Routes
        )
    }

    func loadAppConfiguration() async {
        await loadEnterpriseConfiguration()
        do {
            let configuration = try await api.appSystemConfiguration()
            remoteConfiguration = configuration
            h5DownloadUrl = configuration.h5DownloadUrl
            if let routes = configuration.h5Routes {
                h5Routes = routes
                defaults.set(routes.dictionary, forKey: h5RoutesKey)
            } else {
                h5Routes = .standard
                defaults.removeObject(forKey: h5RoutesKey)
            }
            if let url = configuration.h5BaseURL {
                defaults.set(url.absoluteString, forKey: h5DownloadUrlKey)
            } else {
                defaults.removeObject(forKey: h5DownloadUrlKey)
            }
            JYHDiagnostics.log(
                "配置",
                "H5 配置已更新 h5DownloadUrl=\(h5DownloadUrl) h5BaseURL=\(JYHDiagnostics.redactedURL(h5BaseURL)) routes=\(h5Routes.dictionary)"
            )
        } catch {
            // Keep the cached URL so an unavailable config endpoint does not block navigation.
            JYHDiagnostics.log(
                "配置",
                "H5 配置读取失败，继续使用缓存 h5DownloadUrl=\(h5DownloadUrl) error=\(error.localizedDescription)"
            )
        }
    }

    private func loadEnterpriseConfiguration() async {
        do {
            let key = "JYH_ENTERPRISE_INFO"
            let value = try await api.publicConfiguration(key: key)
            if let institutions = lenderInstitutions(from: value) {
                lenderInstitutions = institutions
                JYHDiagnostics.log(
                    "企业配置",
                    "读取成功 count=\(institutions.count) current=\(currentLenderInstitution?.name ?? "无")"
                )
            } else {
                JYHDiagnostics.log(
                    "企业配置",
                    "接口返回内容无法识别 type=\(String(describing: type(of: value)))"
                )
            }
        } catch {
            JYHDiagnostics.log(
                "企业配置",
                "读取失败，使用本地兜底 error=\(error.localizedDescription)"
            )
        }
    }

    private func lenderInstitutions(from value: Any) -> [LenderInstitution]? {
        if let text = value as? String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("["),
               let data = trimmed.data(using: .utf8),
               let names = try? JSONSerialization.jsonObject(with: data) as? [String] {
                return Self.institutions(fromNames: names.joined(separator: "\n"))
            }
            if trimmed.hasPrefix("{"),
               let data = trimmed.data(using: .utf8),
               let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = root["institutions"] as? [[String: Any]] {
                return items.compactMap { item in
                    let name = item.string("name").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return nil }
                    return LenderInstitution(
                        id: item.string("id", fallback: name),
                        name: name
                    )
                }
            }
            return Self.institutions(fromNames: trimmed)
        }

        if let names = value as? [String] {
            return Self.institutions(fromNames: names.joined(separator: "\n"))
        }

        guard let root = value as? [String: Any],
              let items = root["institutions"] as? [[String: Any]] else {
            return nil
        }
        return items.compactMap { item in
            let name = item.string("name").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return LenderInstitution(
                id: item.string("id", fallback: name),
                name: name
            )
        }
    }

    private static func institutions(fromNames value: String) -> [LenderInstitution] {
        value
            .replacingOccurrences(of: "，", with: "\n")
            .replacingOccurrences(of: ",", with: "\n")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, name in
                LenderInstitution(id: "configured-lender-\(index)", name: name)
            }
    }

    func requestLogin() {
        showLogin = true
    }

    func login(method: LoginMethod, principal: String, credential: String) async -> Bool {
        let normalizedPrincipal = principal.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCredential = method == .code
            ? credential.trimmingCharacters(in: .whitespacesAndNewlines)
            : credential
        JYHDiagnostics.log(
            "登录",
            "请求开始 method=\(method.rawValue) principal=\(JYHDiagnostics.maskedPrincipal(normalizedPrincipal)) selectedTab=\(selectedTab.rawValue) hasEnteredApp=\(hasEnteredApp)"
        )

        guard !normalizedPrincipal.isEmpty else {
            showToast("请输入手机号或账号")
            return false
        }
        if method == .code {
            guard normalizedPrincipal.count == 11,
                  normalizedPrincipal.allSatisfy(\.isNumber) else {
                showToast("请输入正确的手机号")
                return false
            }
            guard normalizedCredential.count == 6,
                  normalizedCredential.allSatisfy(\.isNumber) else {
                showToast("请输入6位验证码")
                return false
            }
        }
        guard !normalizedCredential.isEmpty else {
            showToast(method == .code ? "请输入验证码" : "请输入密码")
            return false
        }

        isBusy = true
        defer { isBusy = false }
        do {
            let result: TokenBundle
            switch method {
            case .password:
                result = try await api.loginPassword(userName: normalizedPrincipal, password: normalizedCredential)
            case .code:
                result = try await api.loginWithCode(mobile: normalizedPrincipal, code: normalizedCredential)
            }
            defaults.set(result.accessToken, forKey: tokenKey)
            isLoggedIn = true
            hasEnteredApp = true
            selectedTab = .home
            showLogin = false
            showToast("登录成功")
            JYHDiagnostics.log(
                "登录",
                "登录成功 token=\(JYHDiagnostics.tokenStatus(result.accessToken)) selectedTab=\(selectedTab.rawValue) hasEnteredApp=\(hasEnteredApp) h5BaseURL=\(JYHDiagnostics.redactedURL(h5BaseURL))"
            )
            JYHDiagnostics.log("H5", "路由配置 routes=\(h5Routes.dictionary)")
            await refreshAll()
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    func sendCode(mobile: String) async -> Bool {
        guard mobile.count == 11 else {
            showToast("请输入有效的手机号")
            return false
        }
        isBusy = true
        defer { isBusy = false }
        do {
            try await api.sendLoginCode(mobile: mobile)
            showToast("验证码已发送")
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    func changePassword(code: String, newPassword: String) async -> String? {
        guard isLoggedIn else {
            return "登录状态已失效，请重新登录"
        }
        let mobile = user.mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        guard mobile.count == 11, mobile.allSatisfy(\.isNumber) else {
            return "未获取到有效手机号，请重新登录后再试"
        }

        isBusy = true
        defer { isBusy = false }
        do {
            let activeToken = token
            let smsFlag = try await api.checkUpdatePasswordCode(
                mobile: mobile,
                code: code,
                token: activeToken
            )
            try await api.resetPassword(
                mobile: mobile,
                newPassword: newPassword,
                smsFlag: smsFlag
            )
            defaults.removeObject(forKey: tokenKey)
            isLoggedIn = false
            hasEnteredApp = false
            user = .guest
            overview = .init()
            repayment = .init()
            showToast("密码修改成功，请重新登录")
            return nil
        } catch {
            let message = error.localizedDescription
            showToast(message)
            return message
        }
    }

    func updateAvatar(data: Data) async -> String? {
        guard isLoggedIn, !token.isEmpty else {
            return "登录状态已失效，请重新登录"
        }

        isBusy = true
        defer { isBusy = false }
        do {
            let fileName = "avatar-\(Int(Date().timeIntervalSince1970)).jpg"
            let path = try await api.uploadAvatar(
                data: data,
                fileName: fileName,
                token: token
            )
            try await api.updateUserInfo(token: token, pic: path)
            user.avatar = path
            avatarRevision &+= 1
            JYHDiagnostics.log("头像", "头像已更新 path=\(path)")
            showToast("头像已更新")
            return nil
        } catch {
            let message = error.localizedDescription
            showToast(message)
            return message
        }
    }

    func logout() {
        defaults.removeObject(forKey: tokenKey)
        isLoggedIn = false
        hasEnteredApp = false
        user = .guest
        overview = .init()
        repayment = .init()
        showToast("已退出登录")
    }

    func handleH5AuthExpired(reason: String) {
        JYHDiagnostics.log("H5", "收到 authExpired reason=\(reason)，清除登录态并展示登录页")
        invalidateSession()
    }

    func destroyAccount() async -> Bool {
        guard !token.isEmpty else {
            hasEnteredApp = false
            return true
        }

        isBusy = true
        defer { isBusy = false }
        do {
            try await api.destroyUser(token: token, force: false)
            defaults.removeObject(forKey: tokenKey)
            isLoggedIn = false
            hasEnteredApp = false
            user = .guest
            overview = .init()
            repayment = .init()
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    func refreshAll() async {
        await loadAppConfiguration()
        guard !token.isEmpty else { return }
        await loadProfile()
        guard isLoggedIn else { return }
        async let kycResult: Void = loadKYCSteps()
        async let loanResult: Void = loadLoanOverview()
        async let repaymentResult: Void = loadRepayment()
        async let applicationResult: Void = loadStoredLoanApplicationIfNeeded()
        _ = await (kycResult, loanResult, repaymentResult, applicationResult)
    }

    func loadProfile() async {
        guard !token.isEmpty else { return }
        do {
            let data = try await api.userProfile(token: token)
            user = UserProfile(
                id: data.string("userId", fallback: data.string("id")),
                nickName: data.string("nickName", fallback: data.string("userName", fallback: "\(AppConfig.appName)用户")),
                mobile: data.string("mobile", fallback: data.string("userMobile")),
                avatar: data.string("pic", fallback: data.string("avatar")),
                borrowFlag: data.int("borrowFlag"),
                realNameVerified: data.bool("realNameVerified", fallback: data.bool("isIdentityChecked")),
                memberLevel: data.string("levelName", fallback: "实名用户")
            )
            if user.borrowFlag != 0 {
                storedLoanApplication = nil
            }
        } catch APIError.unauthorized {
            invalidateSession()
        } catch {
            // Keep the last known user and let explicit actions surface errors.
        }
    }

    func loadStoredLoanApplicationIfNeeded() async {
        guard isLoggedIn, user.borrowFlag == 0 else {
            storedLoanApplication = nil
            return
        }

        let identity = user.id.isEmpty ? user.mobile : user.id
        guard !identity.isEmpty else {
            JYHDiagnostics.log("申请状态", "无法读取申请：缺少用户标识")
            return
        }
        let key = "\(identity)JYHLoanApplicationV1"

        do {
            let value = try await api.otherConfiguration(key: key, token: token)
            guard var dictionary = configurationDictionary(from: value) else {
                storedLoanApplication = nil
                return
            }

            let deadline = parseISODate(dictionary.string("reviewDeadlineAt"))
            let status = dictionary.string("status")
            if status == "reviewing",
               let deadline,
               Date() >= deadline {
                let now = ISO8601DateFormatter().string(from: Date())
                dictionary["status"] = "rejected"
                dictionary["decisionSource"] = "client_timeout"
                dictionary["rejectedAt"] = now
                dictionary["updatedAt"] = now
                try await saveStoredLoanApplication(dictionary, key: key)
            }

            storedLoanApplication = StoredLoanApplication(
                applicationId: dictionary.string("applicationId", fallback: dictionary.string("id")),
                status: dictionary.string("status"),
                principal: dictionary.double("principal"),
                termMonths: dictionary.int("termMonths"),
                productName: dictionary.string("productName", fallback: "\(AppConfig.appName)借款服务"),
                submittedAt: parseISODate(dictionary.string("submittedAt")),
                reviewDeadlineAt: parseISODate(dictionary.string("reviewDeadlineAt"))
            )
            JYHDiagnostics.log(
                "申请状态",
                "读取成功 id=\(dictionary.string("applicationId")) status=\(dictionary.string("status")) deadline=\(dictionary.string("reviewDeadlineAt"))"
            )
        } catch {
            JYHDiagnostics.log("申请状态", "读取失败 error=\(error.localizedDescription)")
        }
    }

    private func saveStoredLoanApplication(_ dictionary: [String: Any], key: String) async throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        guard let value = String(data: data, encoding: .utf8) else {
            throw APIError.invalidResponse
        }
        try await api.saveOtherConfiguration(
            key: key,
            value: value,
            remark: "金瀛花借款申请状态",
            token: token
        )
    }

    private func configurationDictionary(from value: Any) -> [String: Any]? {
        if let string = value as? String,
           let data = string.data(using: .utf8),
           let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return dictionary
        }
        guard let dictionary = value as? [String: Any] else { return nil }
        if let parameterValue = dictionary["paramValue"] as? [String: Any] {
            return parameterValue
        }
        if let parameterValue = dictionary["paramValue"] as? String,
           let data = parameterValue.data(using: .utf8),
           let nested = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return nested
        }
        return dictionary
    }

    private func parseISODate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    func loadLoanOverview() async {
        guard !token.isEmpty else { return }
        do {
            let data = try await api.loanProducts(token: token)
            let productValues = data["loanProductList"] as? [[String: Any]] ?? []
            let products = productValues.map { item in
                LoanProduct(
                    id: item.string("goodsId", fallback: UUID().uuidString),
                    title: item.string("goodsName", fallback: item.string("productName", fallback: "\(AppConfig.appName)借款服务")),
                    subtitle: item.string("description", fallback: "额度及审核结果以实际评估为准"),
                    maximumAmount: item.double("maxLoanAmount", fallback: item.double("amount", fallback: 200_000)) / 100,
                    annualRate: item.string("annualRate", fallback: "7.2%起")
                )
            }
            let apiProducts = data["apiProductList"] as? [[String: Any]] ?? []
            overview = LoanOverview(
                estimatedAmount: data.double("totalBorrowingMoney", fallback: overview.estimatedAmount * 100) / 100,
                availableAmount: products.first?.maximumAmount == 0 ? 8_000 : min(products.first?.maximumAmount ?? 8_000, 8_000),
                minimumRate: 7.2,
                maximumRate: 24,
                products: products.isEmpty && apiProducts.isEmpty ? overview.products : products
            )
        } catch APIError.unauthorized {
            invalidateSession()
        } catch {
            // Products can be unavailable until KYC is complete.
        }
    }

    func loadRepayment() async {
        guard !token.isEmpty else { return }
        do {
            let data = try await api.repaymentCounts(token: token)
            repayment.loanOrderCount = data.int("loanOrderCount")
            repayment.shopOrderCount = data.int("shopOrderCount")
        } catch {
            // Counts are non-critical and should not interrupt the page.
        }
    }

    func loadFeedbackRecords() async throws -> [FeedbackRecord] {
        guard !token.isEmpty else { throw APIError.unauthorized }
        let key = try feedbackConfigurationKey()
        let value = try await api.otherConfiguration(key: key, token: token)
        guard let dictionary = configurationDictionary(from: value),
              let items = dictionary["items"] as? [[String: Any]] else {
            return []
        }
        return items.compactMap(feedbackRecord(from:))
    }

    func submitFeedback(
        categoryId: String,
        categoryName: String,
        content: String,
        attachmentPaths: [String],
        allowContact: Bool
    ) async throws -> FeedbackRecord {
        guard !token.isEmpty else { throw APIError.unauthorized }
        let key = try feedbackConfigurationKey()
        let existing = try await loadFeedbackRecords()
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyyMMddHHmmss"
        let identifier = "FB\(formatter.string(from: now))\(String(Int.random(in: 100...999)))"
        let createdAt = ISO8601DateFormatter().string(from: now)
        let record = FeedbackRecord(
            id: identifier,
            feedbackId: identifier,
            categoryId: categoryId,
            categoryName: categoryName,
            content: content,
            contactMobile: allowContact ? user.mobile : "",
            allowContact: allowContact,
            attachmentPaths: attachmentPaths,
            status: "submitted",
            reply: "",
            createdAt: now
        )
        let recordDictionary: [String: Any] = [
            "feedbackId": record.feedbackId,
            "categoryId": record.categoryId,
            "categoryName": record.categoryName,
            "content": record.content,
            "contactMobile": record.contactMobile,
            "allowContact": record.allowContact,
            "attachmentPaths": record.attachmentPaths,
            "status": record.status,
            "reply": record.reply,
            "createdAt": createdAt,
            "updatedAt": createdAt,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "platform": "iOS",
            "osVersion": UIDevice.current.systemVersion
        ]
        let records = ([recordDictionary] + existing.prefix(19).map(feedbackDictionary(from:)))
        let payload: [String: Any] = [
            "schemaVersion": 1,
            "items": records
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let value = String(data: data, encoding: .utf8) else {
            throw APIError.invalidResponse
        }
        try await api.saveOtherConfiguration(
            key: key,
            value: value,
            remark: "金瀛花意见反馈",
            token: token
        )
        return record
    }

    func uploadFeedbackAttachment(_ data: Data, fileName: String) async throws -> String {
        guard !token.isEmpty else { throw APIError.unauthorized }
        return try await api.uploadImage(
            data: data,
            fileName: fileName,
            contentType: "image/jpeg",
            token: token
        )
    }

    private func feedbackConfigurationKey() throws -> String {
        let identity = user.id.isEmpty ? user.mobile : user.id
        guard !identity.isEmpty else {
            throw APIError.server(code: "feedback_identity", message: "当前账号缺少用户标识")
        }
        return "\(identity)JYHFeedbackV1"
    }

    private func feedbackRecord(from dictionary: [String: Any]) -> FeedbackRecord? {
        let feedbackId = dictionary.string("feedbackId", fallback: dictionary.string("id"))
        let content = dictionary.string("content")
        guard !feedbackId.isEmpty, !content.isEmpty else { return nil }
        return FeedbackRecord(
            id: feedbackId,
            feedbackId: feedbackId,
            categoryId: dictionary.string("categoryId"),
            categoryName: dictionary.string("categoryName", fallback: "其他问题"),
            content: content,
            contactMobile: dictionary.string("contactMobile"),
            allowContact: dictionary.bool("allowContact", fallback: false),
            attachmentPaths: dictionary["attachmentPaths"] as? [String] ?? [],
            status: dictionary.string("status", fallback: "submitted"),
            reply: dictionary.string("reply"),
            createdAt: parseISODate(dictionary.string("createdAt"))
        )
    }

    private func feedbackDictionary(from record: FeedbackRecord) -> [String: Any] {
        [
            "feedbackId": record.feedbackId,
            "categoryId": record.categoryId,
            "categoryName": record.categoryName,
            "content": record.content,
            "contactMobile": record.contactMobile,
            "allowContact": record.allowContact,
            "attachmentPaths": record.attachmentPaths,
            "status": record.status,
            "reply": record.reply,
            "createdAt": record.createdAt.map { ISO8601DateFormatter().string(from: $0) } ?? ""
        ]
    }

    func loadKYCSteps() async {
        guard !token.isEmpty else { return }
        do {
            let values = try await api.kycSteps(token: token)
            kycSteps = values.enumerated().map { index, item in
                KYCStep(
                    id: item.string("collectType", fallback: item.string("code", fallback: "\(index)")),
                    collectType: item.string("collectType", fallback: item.string("code")),
                    name: item.string("name", fallback: item.string("title", fallback: "认证资料")),
                    status: item.string("authenticationStatus")
                )
            }
        } catch {
            // The H5 flow remains the fallback when step metadata is unavailable.
        }
    }

    func submitRealName(name: String, identityNo: String) async -> Bool {
        guard token.isEmpty == false else {
            requestLogin()
            return false
        }
        guard name.trimmingCharacters(in: .whitespaces).count > 1 else {
            showToast("请输入真实姓名")
            return false
        }
        guard identityNo.count == 18 else {
            showToast("请输入正确的身份证号")
            return false
        }

        isBusy = true
        defer { isBusy = false }
        do {
            try await api.setRealName(name: name, identityNo: identityNo, token: token)
            user.realNameVerified = true
            showToast("实名认证成功")
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }

    private func invalidateSession() {
        defaults.removeObject(forKey: tokenKey)
        isLoggedIn = false
        showLogin = true
    }
}

enum MainTab: String, CaseIterable, Identifiable {
    case home = "首页"
    case profile = "我的"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "借款"
        case .profile: return "我的"
        }
    }
}
