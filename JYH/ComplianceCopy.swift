import Foundation

struct LenderInstitution: Identifiable, Equatable {
    let id: String
    let name: String
}

enum JYLenderDirectory {
    static let all: [LenderInstitution] = [
        LenderInstitution(
            id: "guiyang-yunyan-hetai",
            name: "贵阳市云岩区和泰小额贷款有限公司"
        )
    ]

    static var current: LenderInstitution {
        all[0]
    }
}

enum JYLegal {
    static let privacyProtocolKey = "JYH_PRIVACY_PROTOC"
    static let registerProtocolKey = "JYH_REGISTER_PROTOC"
    static let enterpriseInfoKey = "JYH_ENTERPRISE_INFO"
}

enum JYCopy {
    static let partnerLenderName = JYLenderDirectory.current.name
    static let providerDisclosure = "合作机构：\(partnerLenderName)"
    static let approvalDisclosure = "额度、期限及利率以实际审批和借款协议为准"
    static let rateDisclosure = "年化利率及费用以借款协议为准"
    static let privacyNotice = "身份信息仅用于实名认证、风险审核及履行法定义务"
    static let repaymentNotice = "请按借款合同约定及时还款，逾期可能影响信用记录"
}
