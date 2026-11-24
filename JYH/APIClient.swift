import CommonCrypto
import Foundation
import UIKit

struct APIClient {
    static let shared = APIClient()

    let baseURL = AppConfig.apiBaseURL
    let resourceBaseURL = AppConfig.ossBaseURL

    func appSystemConfiguration() async throws -> AppRemoteConfiguration {
        let domainValue = try? await publicConfiguration(key: AppConfig.appName)
        let routeValue = try? await publicConfiguration(key: AppConfig.h5ConfigurationKey)
        let domainDictionary = configurationDictionary(from: domainValue)
        let routeDictionary = configurationDictionary(from: routeValue)

        let explicitRoutePayload = routeDictionary?["h5Routes"] as? [String: Any]
            ?? routeDictionary?["h5RoutePaths"] as? [String: Any]
            ?? (routeDictionary?["h5Routes"] as? String)
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let directRouteKeys = Set([
            "identityCard", "certificationResult", "profileInformation", "status",
            "borrow", "loanApplication", "loanResult", "bill", "billDetail",
            "customerService", "chat"
        ])
        let directRoutePayload = routeDictionary?.filter { directRouteKeys.contains($0.key) }
        let routePayload = explicitRoutePayload
            ?? ((directRoutePayload?.isEmpty == false) ? directRoutePayload : nil)
        let validRoutes = routePayload.flatMap { payload -> H5RoutePaths? in
            guard payload.values.contains(where: {
                ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }) else { return nil }
            return H5RoutePaths(dictionary: payload)
        }

        return AppRemoteConfiguration(
            h5DownloadUrl: domainDictionary?.string("h5DownloadUrl") ?? "",
            serviceLink: domainDictionary?.string("serviceLink") ?? "",
            serviceSwitch: domainDictionary?.bool("serviceSwitch", fallback: false) ?? false,
            h5Routes: validRoutes
        )
    }

    private func configurationDictionary(from value: Any?) -> [String: Any]? {
        guard let value else { return nil }
        let payload: Any
        if let text = value as? String,
           let data = text.data(using: .utf8),
           let decoded = try? JSONSerialization.jsonObject(with: data) {
            payload = decoded
        } else {
            payload = value
        }
        return payload as? [String: Any]
    }

    func otherConfiguration(key: String, token: String) async throws -> Any {
        try await request(
            path: "/mall_admin/ua/app/sys_config/get/other/value/config/\(key)",
            method: .get,
            token: token
        )
    }

    func publicConfiguration(key: String) async throws -> Any {
        try await request(
            path: "/mall_admin/ua/app/sys_config/get/value/config/\(key)",
            method: .get,
            requiresAuth: false
        )
    }

    func legalDocument(type: LegalDocumentType) async throws -> String {
        async let documentValue = publicConfiguration(key: type.configurationKey)
        async let enterpriseValue = publicConfiguration(key: JYLegal.enterpriseInfoKey)

        let (documentPayload, enterprisesPayload) = try await (documentValue, enterpriseValue)
        guard let html = configurationText(from: documentPayload),
              !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.invalidResponse
        }
        let enterpriseNames = configurationNames(from: enterprisesPayload)
        let enterpriseText = enterpriseNames
            .map(htmlEscaped)
            .joined(separator: "，")
        return html.replacingOccurrences(
            of: "${enterpriseNames}",
            with: enterpriseText
        )
    }

    func saveOtherConfiguration(
        key: String,
        value: String,
        remark: String,
        token: String
    ) async throws {
        _ = try await request(
            path: "/mall_admin/p/sys_config/ua/other/save",
            method: .post,
            body: [
                "paramKey": key,
                "paramValue": value,
                "remark": remark
            ],
            token: token
        )
    }

    func loginPassword(userName: String, password: String) async throws -> TokenBundle {
        let data = try await request(
            path: "/mall_auth/ua/login",
            method: .post,
            body: [
                "sysType": 0,
                "socialType": 6,
                "tempUid": AppConfig.tempUid,
                "userName": userName,
                "passWord": AESECB.encrypt(password),
                "appBrand": AppConfig.appName,
                "osName": "iOS",
                "loginStatus": 2
            ],
            requiresAuth: false
        )
        return try token(from: data)
    }

    func loginWithCode(mobile: String, code: String) async throws -> TokenBundle {
        let data = try await request(
            path: "/mall_auth/ua/login_with_code",
            method: .post,
            body: [
                "sysType": 0,
                "socialType": 6,
                "tempUid": AppConfig.tempUid,
                "userName": mobile,
                "mobile": mobile,
                "validCode": code,
                "appBrand": AppConfig.appName,
                "osName": "iOS",
                "loginStatus": 1
            ],
            requiresAuth: false
        )
        return try token(from: data)
    }

    func sendLoginCode(mobile: String) async throws {
        _ = try await request(
            path: "/mall_biz/ua/sms/verification_code/login_wtocode",
            method: .put,
            body: [
                "mobile": mobile
            ],
            requiresAuth: false
        )
    }

    func userProfile(token: String) async throws -> [String: Any] {
        try dictionary(
            from: await request(
                path: "/mall_user/user/ma/user_detail_info",
                method: .get,
                token: token
            )
        )
    }

    func checkUpdatePasswordCode(mobile: String, code: String, token: String) async throws -> String {
        let value = try await request(
            path: "/mall_biz/ua/sms/verification_code/check_update_pwd",
            method: .put,
            body: [
                "mobile": mobile,
                "validCode": code
            ],
            token: token
        )
        if let flag = value as? String, !flag.isEmpty {
            return flag
        }
        if let dictionary = value as? [String: Any] {
            let flag = dictionary.string("checkUpdatePwdSmsFlag", fallback: dictionary.string("smsFlag"))
            if !flag.isEmpty {
                return flag
            }
        }
        throw APIError.invalidResponse
    }

    func resetPassword(mobile: String, newPassword: String, smsFlag: String) async throws {
        _ = try await request(
            path: "/mall_auth/ua/forget_password",
            method: .put,
            body: [
                "checkUpdatePwdSmsFlag": smsFlag,
                "mobile": mobile,
                "newPassword": AESECB.encrypt(newPassword),
                "sysType": 0
            ],
            requiresAuth: false
        )
    }

    func updateUserInfo(token: String, nickName: String? = nil, pic: String? = nil) async throws {
        var body: [String: Any] = [:]
        if let nickName {
            body["nickName"] = nickName
        }
        if let pic {
            body["pic"] = pic
        }
        guard !body.isEmpty else { return }
        _ = try await request(
            path: "/mall_user/user/set_user_info",
            method: .put,
            body: body,
            token: token
        )
    }

    func uploadAvatar(data: Data, fileName: String, token: String) async throws -> String {
        try await uploadImage(
            data: data,
            fileName: fileName,
            contentType: "image/jpeg",
            token: token
        )
    }

    func uploadImage(
        data: Data,
        fileName: String,
        contentType: String,
        token: String
    ) async throws -> String {
        let value = try await request(
            path: "/mall_biz/ua/oss/get_batch_pre_sign_url",
            method: .get,
            body: ["fileNames": fileName],
            token: token
        )
        guard let items = value as? [[String: Any]],
              let item = items.first,
              let preSignURL = URL(string: item.string("preSignUrl")) else {
            throw APIError.invalidResponse
        }

        try await uploadData(to: preSignURL, contentType: contentType, data: data)

        let directory = item.string("dir")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let uploadedName = item.string("fileName", fallback: fileName)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !uploadedName.isEmpty else {
            throw APIError.invalidResponse
        }
        return "/" + ([directory, uploadedName].filter { !$0.isEmpty }).joined(separator: "/")
    }

    func loanProducts(token: String) async throws -> [String: Any] {
        try dictionary(
            from: await request(
                path: "/mall-connect/goods/list",
                method: .post,
                body: [:],
                token: token
            )
        )
    }

    func repaymentCounts(token: String) async throws -> [String: Any] {
        try dictionary(
            from: await request(
                path: "/mall-connect/goods/waitRepayCount",
                method: .post,
                body: [:],
                token: token
            )
        )
    }

    func kycSteps(token: String) async throws -> [[String: Any]] {
        let value = try await request(
            path: "/mall-connect/kyc/enterDataSortList",
            method: .get,
            token: token
        )
        return value as? [[String: Any]] ?? []
    }

    func userExtension(token: String) async throws -> [String: Any] {
        try dictionary(
            from: await request(
                path: "/mall_user/user_extension/get_info",
                method: .get,
                token: token
            )
        )
    }

    func setRealName(name: String, identityNo: String, token: String) async throws {
        _ = try await request(
            path: "/mall_payment/allinpay/member/set_real_name",
            method: .post,
            body: ["name": name, "identityNo": identityNo],
            token: token
        )
    }

    func destroyUser(token: String, force: Bool) async throws {
        _ = try await request(
            path: "/mall_user/user/destroy_user",
            method: .get,
            body: ["forceDestroy": force],
            token: token
        )
    }

    func loanFlowURL(baseURL: URL, token: String, routes: H5RoutePaths) -> URL? {
        H5URLBuilder.url(
            baseURL: baseURL,
            route: .loanApplication(goodsID: nil),
            token: token,
            routes: routes
        )
    }

    func repaymentFlowURL(baseURL: URL, token: String, routes: H5RoutePaths) -> URL? {
        H5URLBuilder.url(
            baseURL: baseURL,
            route: .bill(orderType: "loan"),
            token: token,
            routes: routes
        )
    }

    func resourceURL(_ path: String, cacheKey: String = "") -> URL? {
        guard !path.isEmpty else { return nil }
        let resolved = path.lowercased().hasPrefix("http")
            ? URL(string: path)
            : URL(string: path, relativeTo: resourceBaseURL)
        guard
            !cacheKey.isEmpty,
            let resolved,
            var components = URLComponents(url: resolved, resolvingAgainstBaseURL: false)
        else {
            return resolved
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "avatarRevision" }
        items.append(URLQueryItem(name: "avatarRevision", value: cacheKey))
        components.queryItems = items
        return components.url
    }

    private func token(from value: Any) throws -> TokenBundle {
        guard let dictionary = value as? [String: Any] else {
            throw APIError.invalidResponse
        }
        let tokenValue = dictionary["tokenInfo"] as? [String: Any] ?? dictionary
        let accessToken = tokenValue.string("accessToken")
        guard !accessToken.isEmpty else {
            throw APIError.server(code: dictionary.string("code"), message: dictionary.string("msg", fallback: "未获取到登录凭证"))
        }
        return TokenBundle(
            accessToken: accessToken,
            refreshToken: tokenValue.string("refreshToken"),
            expiresIn: tokenValue["expiresIn"] as? Double
        )
    }

    private func dictionary(from value: Any) throws -> [String: Any] {
        guard let dictionary = value as? [String: Any] else {
            throw APIError.invalidResponse
        }
        return dictionary
    }

    private func configurationText(from value: Any) -> String? {
        if let text = value as? String {
            return text
        }
        guard let dictionary = value as? [String: Any] else { return nil }
        if let text = dictionary["paramValue"] as? String {
            return text
        }
        return dictionary["value"] as? String
            ?? dictionary["content"] as? String
    }

    private func configurationNames(from value: Any) -> [String] {
        if let text = value as? String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("["),
               let data = trimmed.data(using: .utf8),
               let names = try? JSONSerialization.jsonObject(with: data) as? [String] {
                return normalizeConfigurationNames(names)
            }
            return normalizeConfigurationNames(
                trimmed
                    .replacingOccurrences(of: "，", with: "\n")
                    .replacingOccurrences(of: ",", with: "\n")
                    .components(separatedBy: .newlines)
            )
        }
        if let names = value as? [String] {
            return normalizeConfigurationNames(names)
        }
        return []
    }

    private func normalizeConfigurationNames(_ values: [String]) -> [String] {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func htmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    private func request(
        path: String,
        method: Method,
        body: [String: Any]? = nil,
        token: String? = nil,
        requiresAuth: Bool = true
    ) async throws -> Any {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        if method == .get, let body, !body.isEmpty {
            components.queryItems = body.map {
                URLQueryItem(name: $0.key, value: String(describing: $0.value))
            }
        }

        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("zh_CN", forHTTPHeaderField: "locale")
        request.setValue(
            "\(UIDevice.current.model) - \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            forHTTPHeaderField: "Device-Info"
        )

        if let token, !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        } else if requiresAuth {
            throw APIError.unauthorized
        }

        if method != .get, let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw APIError.unauthorized
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(code: "\(http.statusCode)", message: "服务器连接异常（\(http.statusCode)）")
        }

        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }

        if let code = root["code"] as? String, !code.isEmpty, code != "00000" {
            let normalizedCode = code.uppercased()
            if normalizedCode == "A00004" || normalizedCode == "A00008" {
                throw APIError.unauthorized
            }
            throw APIError.server(code: code, message: root.string("msg"))
        }

        if let success = root["success"] as? Bool, !success {
            throw APIError.server(code: root.string("code"), message: root.string("msg"))
        }

        return root["data"] ?? root
    }

    private func uploadData(to url: URL, contentType: String, data: Data) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 30
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(
                code: "\(http.statusCode)",
                message: "头像上传失败（\(http.statusCode)）"
            )
        }
    }
}

enum AESECB {
    static func encrypt(_ plainText: String) -> String {
        let key = Array("-mall--password-".utf8)
        let input = Array("\(Int(Date().timeIntervalSince1970 * 1000))\(plainText)".utf8)
        var output = Data(count: input.count + kCCBlockSizeAES128)
        var outputLength = 0
        let outputCapacity = output.count

        let status = output.withUnsafeMutableBytes { outputBuffer in
            input.withUnsafeBytes { inputBuffer in
                key.withUnsafeBytes { keyBuffer in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                        keyBuffer.baseAddress,
                        key.count,
                        nil,
                        inputBuffer.baseAddress,
                        input.count,
                        outputBuffer.baseAddress,
                        outputCapacity,
                        &outputLength
                    )
                }
            }
        }

        guard status == kCCSuccess else { return plainText }
        output.removeSubrange(outputLength..<output.count)
        return output.base64EncodedString()
    }
}
