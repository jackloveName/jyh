import Foundation

enum H5PagePath {
    static let root = "/"
    static let identityCard = "/idCard"
    static let certificationResult = "/certificationResult"
    static let profileInformation = "/info"
    static let status = "/status"
    static let borrow = "/borrow"
    static let loanApplication = "/loan"
    static let loanResult = "/loan/result"
    static let bill = "/bill"
    static let billDetail = "/bill/detail"
    static let customerService = "/chat"

    static func normalized(_ path: String) -> String {
        let value = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return root }
        if let url = URL(string: value),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return value
        }
        let components = value
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        return components.isEmpty ? root : "/" + components.joined(separator: "/")
    }
}

struct H5RoutePaths: Equatable {
    let identityCard: String
    let certificationResult: String
    let profileInformation: String
    let status: String
    let borrow: String
    let loanApplication: String
    let loanResult: String
    let bill: String
    let billDetail: String
    let customerService: String

    static let standard = H5RoutePaths(dictionary: [:])

    init(dictionary: [String: Any]) {
        identityCard = Self.path(in: dictionary, keys: ["identityCard"], fallback: H5PagePath.identityCard)
        certificationResult = Self.path(in: dictionary, keys: ["certificationResult"], fallback: H5PagePath.certificationResult)
        profileInformation = Self.path(in: dictionary, keys: ["profileInformation", "info"], fallback: H5PagePath.profileInformation)
        status = Self.path(in: dictionary, keys: ["status"], fallback: H5PagePath.status)
        borrow = Self.path(in: dictionary, keys: ["borrow"], fallback: H5PagePath.borrow)
        loanApplication = Self.path(in: dictionary, keys: ["loanApplication", "loan"], fallback: H5PagePath.loanApplication)
        loanResult = Self.path(in: dictionary, keys: ["loanResult"], fallback: H5PagePath.loanResult)
        bill = Self.path(in: dictionary, keys: ["bill"], fallback: H5PagePath.bill)
        billDetail = Self.path(in: dictionary, keys: ["billDetail"], fallback: H5PagePath.billDetail)
        customerService = Self.path(
            in: dictionary,
            keys: ["customerService", "chat"],
            fallback: H5PagePath.customerService
        )
    }

    var dictionary: [String: String] {
        [
            "identityCard": identityCard,
            "certificationResult": certificationResult,
            "profileInformation": profileInformation,
            "status": status,
            "borrow": borrow,
            "loanApplication": loanApplication,
            "loanResult": loanResult,
            "bill": bill,
            "billDetail": billDetail,
            "customerService": customerService
        ]
    }

    private static func path(
        in dictionary: [String: Any],
        keys: [String],
        fallback: String
    ) -> String {
        for key in keys {
            if let value = dictionary[key] as? String,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return H5PagePath.normalized(value)
            }
        }
        return fallback
    }
}

enum H5FlowRoute: Hashable {
    case identityCard
    case faceRecognition
    case profileInformation
    case bill(orderType: String)
    case loanList
    case loanApplication(goodsID: String?)
    case loanResult
    case customerService

    func path(using routes: H5RoutePaths) -> String {
        switch self {
        case .identityCard, .faceRecognition:
            // The H5 currently advances the ID-card and face steps from the same route.
            return routes.identityCard
        case .profileInformation:
            return routes.profileInformation
        case .bill:
            return routes.bill
        case .loanList:
            return routes.loanApplication
        case .loanApplication:
            return routes.loanApplication
        case .loanResult:
            return routes.loanResult
        case .customerService:
            return routes.customerService
        }
    }

    var additionalQueryItems: [URLQueryItem] {
        switch self {
        case .bill(let orderType):
            return [
                URLQueryItem(name: "orderType", value: orderType),
                URLQueryItem(name: "sourcePage", value: "app")
            ]
        case .loanApplication(let goodsID):
            guard let goodsID, !goodsID.isEmpty else { return [] }
            return [URLQueryItem(name: "goodsId", value: goodsID)]
        case .customerService:
            return [URLQueryItem(name: "nativeEntry", value: "1")]
        default:
            return []
        }
    }
}

enum H5URLBuilder {
    static func url(
        baseURL: URL,
        route: H5FlowRoute,
        token: String,
        routes: H5RoutePaths = .standard
    ) -> URL? {
        guard !token.isEmpty else { return nil }
        let routeValue = route.path(using: routes)
        let absoluteRoute = URL(string: routeValue)
        let hasAbsoluteRoute = absoluteRoute?.scheme?.lowercased().hasPrefix("http") == true
        guard var destination = URLComponents(
            url: hasAbsoluteRoute ? absoluteRoute! : baseURL,
            resolvingAgainstBaseURL: false
        ) else { return nil }

        let managedKeys = Set(["token", "appName", "statusHeight"])
        var baseItems = destination.queryItems ?? []
        baseItems.removeAll { managedKeys.contains($0.name) }
        destination.queryItems = baseItems.isEmpty ? nil : baseItems
        if destination.path.isEmpty {
            destination.path = "/"
        }

        let fragmentSource = hasAbsoluteRoute ? destination.fragment ?? H5PagePath.root : routeValue
        guard var routeComponents = URLComponents(string: fragmentSource) else {
            return nil
        }
        let existingRouteItems = routeComponents.queryItems ?? []
        routeComponents.path = H5PagePath.normalized(routeComponents.path)
        routeComponents.queryItems = existingRouteItems + route.additionalQueryItems + [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "appName", value: AppConfig.appName),
            URLQueryItem(name: "statusHeight", value: "0")
        ]

        guard let fragment = routeComponents.string else { return nil }
        destination.percentEncodedFragment = fragment
        return destination.url
    }
}
