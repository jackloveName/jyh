import SwiftUI

struct ApplicationConditionsGuideView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        GuidePageScaffold(
            title: "申请条件",
            subtitle: "提交申请前，请先确认本人情况和所需资料。",
            symbol: "checkmark.shield.fill"
        ) {
            GuideStatusCard(
                title: store.kycNextStep == .loanReady ? "认证资料已完成" : "请先完成实名认证",
                message: store.kycNextStep == .loanReady
                    ? "当前账号可继续填写借款方案，实际额度及结果以审批为准。"
                    : "按页面提示完成\(store.kycNextStep.actionTitle)，认证完成后可继续申请。",
                color: store.kycNextStep == .loanReady ? JYColor.success : JYColor.warning
            )

            GuideSectionCard(title: "基本申请条件") {
                GuideBulletRow(title: "年满18周岁", message: "具备完全民事行为能力，并以本人真实身份发起申请。", index: "01")
                GuideBulletRow(title: "证件真实有效", message: "持有本人有效居民身份证，且证件信息清晰可识别。", index: "02")
                GuideBulletRow(title: "具备还款能力", message: "有稳定、合法的收入来源，能够按合同约定履行还款义务。", index: "03")
                GuideBulletRow(title: "授权信息核验", message: "同意平台及合作机构依法开展身份核验、风险审核和征信授权。", index: "04")
            }

            GuideSectionCard(title: "申请前准备") {
                GuideChecklist(text: "本人有效身份证原件")
                GuideChecklist(text: "常用手机号及本人相关资料")
                GuideChecklist(text: "合理的借款金额与期限安排")
            }

            GuidePreviewCard(
                kind: .identity,
                title: "实名认证页面示意",
                message: "实际页面只要求按提示完成本人身份核验，不会在指南中展示姓名、证件号码或照片。"
            )

            GuideNoticeCard(
                title: "审核说明",
                message: "满足基本条件不代表一定审批通过。额度、期限、综合融资成本及是否放款均由合作机构结合实际情况独立审核。"
            )
        }
    }
}

struct LoanProcessGuideView: View {
    var body: some View {
        GuidePageScaffold(
            title: "借款流程",
            subtitle: "从身份认证到查看结果，按页面提示逐步完成。",
            symbol: "point.3.connected.trianglepath.dotted"
        ) {
            GuideSectionCard(title: "完整办理流程") {
                GuideStepRow(
                    number: 1,
                    title: "完成实名认证",
                    message: "上传身份证并完成人脸核验，确认申请人为本人。",
                    active: true
                )
                GuideStepRow(
                    number: 2,
                    title: "完善申请资料",
                    message: "补充联系信息、职业和收入等审核所需资料。",
                    active: true
                )
                GuideStepRow(
                    number: 3,
                    title: "选择金额与期限",
                    message: "在页面可借额度和可选期限范围内填写借款方案。",
                    active: true
                )
                GuideStepRow(
                    number: 4,
                    title: "确认并提交申请",
                    message: "核对借款金额、期限、费用及授权协议后提交审核。",
                    active: true
                )
                GuideStepRow(
                    number: 5,
                    title: "查看审批结果",
                    message: "审核结果以页面通知及合作机构最终结论为准。",
                    active: false,
                    showsLine: false
                )
            }

            GuidePreviewCard(
                kind: .loanApplication,
                title: "借款方案页面示意",
                message: "图中金额与期限均为示例，实际可借金额取决于认证、审核结果和产品上限。"
            )

            GuidePreviewCard(
                kind: .identity,
                title: "身份资料页面示意",
                message: "操作示意仅说明页面结构，不包含真实个人资料。"
            )

            GuideNoticeCard(
                title: "提交前请再次确认",
                message: "请核对实际出借机构、综合融资成本、每期应还、到期应还、提前还款及逾期规则，并以最终合同为准。"
            )
        }
    }
}

struct QuotaGuideView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        GuidePageScaffold(
            title: "额度说明",
            subtitle: store.quotaGuideSubtitle,
            symbol: "gauge.with.dots.needle.67percent"
        ) {
            GuideSectionCard(title: "当前额度状态") {
                HStack(alignment: .firstTextBaseline) {
                    Text(store.quotaDisplayText)
                        .font(
                            store.hasRejectedBorrowApplication
                                ? .system(size: 25, weight: .semibold)
                                : .custom("DINAlternate-Bold", size: 34)
                        )
                        .foregroundStyle(JYColor.ink)
                    Spacer()
                    Text(store.quotaStatusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(JYColor.action)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(JYColor.primarySoft, in: Capsule())
                }
                Text(store.quotaDescriptionText)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(3)
            }

            GuideSectionCard(title: "额度如何产生") {
                GuideBulletRow(
                    title: "完成身份与资料核验",
                    message: "实名认证、人脸核验和申请资料状态均需通过。",
                    index: "01"
                )
                GuideBulletRow(
                    title: "查询借款产品",
                    message: "系统获取当前可申请产品及其最高金额限制。",
                    index: "02"
                )
                GuideBulletRow(
                    title: "查询当前可用额度",
                    message: "读取服务端返回的当前可借金额，并受产品上限约束。",
                    index: "03"
                )
            }

            GuidePreviewCard(
                kind: .loanApplication,
                title: "额度与期限展示示意",
                message: "金额、费率和期限以申请页面实时展示及最终合同为准。"
            )

            GuideNoticeCard(
                title: "参考额度不是放款承诺",
                message: "即使页面展示可借额度，仍需经过申请审核。若额度为0或暂时无法获取，请以页面最新状态为准。"
            )
        }
    }
}

struct RepaymentGuideView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        GuidePageScaffold(
            title: "还款说明",
            subtitle: "按合同约定还款，账单会展示每期本金、利息和到期日。",
            symbol: "calendar.badge.checkmark"
        ) {
            GuideSectionCard(title: "还款方式") {
                GuideBulletRow(
                    title: "等额本息",
                    message: "每期还款金额基本一致，具体以借款合同和账单为准。",
                    index: "01"
                )
                GuideBulletRow(
                    title: "按期查询账单",
                    message: "可从“我的账单”查看每期应还、本金、利息和还款状态。",
                    index: "02"
                )
                GuideBulletRow(
                    title: "到期日前完成还款",
                    message: "请确保还款账户状态正常，避免因余额不足产生逾期。",
                    index: "03"
                )
            }

            GuidePreviewCard(
                kind: .billOverview,
                title: "账单列表页面示意",
                message: "示意页面仅展示账单结构和状态，不包含真实账户、金额或还款日期。"
            )

            GuidePreviewCard(
                kind: .billDetail,
                title: "账单详情页面示意",
                message: "示例金额仅用于说明页面结构，每期还款构成为本期本金与本期利息之和。"
            )

            GuideSectionCard(title: "提前还款与逾期") {
                Text("提前还款是否收取费用、逾期费用如何计算，以实际借款合同及出借机构规则为准。逾期可能影响后续服务及信用记录。")
                    .font(.system(size: 13))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(5)
            }

            if store.isLoggedIn {
                NavigationLink(value: AppRoute.h5Bill) {
                    GuideActionLabel(title: "查看我的账单")
                }
                .buttonStyle(PressScaleStyle())
            } else {
                Button {
                    store.requestLogin()
                } label: {
                    GuideActionLabel(title: "登录后查看账单")
                }
                .buttonStyle(PressScaleStyle())
            }
        }
    }
}

private struct GuidePageScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    let symbol: String
    let content: Content

    init(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
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

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                    .frame(maxWidth: .infinity)

                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 10)
            .frame(height: 54)
            .background(Color.white)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GuideHeroCard(title: title, subtitle: subtitle, symbol: symbol)
                    content
                    Text(JYCopy.approvalDisclosure)
                        .font(.system(size: 11))
                        .foregroundStyle(JYColor.tertiaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
            }
            .scrollIndicators(.hidden)
        }
        .background(JYColor.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct GuideHeroCard: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        colors: [JYColor.action, Color(hex: 0x4C9AF7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(JYColor.ink)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: 0xF2F7FF)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

private struct GuideSectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(JYColor.ink)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GuideStatusCard: View {
    let title: String
    let message: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GuideBulletRow: View {
    let title: String
    let message: String
    let index: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(index)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(JYColor.action)
                .frame(width: 28, height: 24)
                .background(JYColor.primarySoft, in: Capsule())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(3)
            }
        }
    }
}

private struct GuideChecklist: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(JYColor.success)
                .frame(width: 22, height: 22)
                .background(Color(hex: 0xEAF8F1), in: Circle())
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(JYColor.ink)
        }
    }
}

private struct GuideStepRow: View {
    let number: Int
    let title: String
    let message: String
    let active: Bool
    var showsLine = true

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 5) {
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(active ? .white : JYColor.tertiaryText)
                    .frame(width: 28, height: 28)
                    .background(active ? JYColor.action : Color(hex: 0xEEF2F7), in: Circle())
                if showsLine {
                    Rectangle()
                        .fill(Color(hex: 0xDCE5F0))
                        .frame(width: 1, height: 40)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(3)
            }
            .padding(.top, 2)
        }
    }
}

private enum GuidePreviewKind {
    case identity
    case loanApplication
    case billOverview
    case billDetail
}

private struct GuidePreviewCard: View {
    let kind: GuidePreviewKind
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Spacer()
                Text("操作示意")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(JYColor.action)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(JYColor.primarySoft, in: Capsule())
            }

            GuidePreviewArtwork(kind: kind)

            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(JYColor.tertiaryText)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GuidePreviewArtwork: View {
    let kind: GuidePreviewKind

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewHeader

            Rectangle()
                .fill(Color(hex: 0xE9EEF5))
                .frame(height: 1)

            previewContent

            HStack(spacing: 5) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("示例界面，不包含真实账户信息")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(JYColor.tertiaryText)
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xF7F9FC), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0xE5EBF3), lineWidth: 1)
        }
    }

    private var previewHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: headerIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    LinearGradient(
                        colors: [JYColor.action, Color(hex: 0x52A0F7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(headerSubtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(JYColor.tertiaryText)
            }

            Spacer()

            Text(headerBadge)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(JYColor.action)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white, in: Capsule())
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch kind {
        case .identity:
            identityPreview
        case .loanApplication:
            loanApplicationPreview
        case .billOverview:
            billOverviewPreview
        case .billDetail:
            billDetailPreview
        }
    }

    private var identityPreview: some View {
        VStack(spacing: 8) {
            GuidePreviewRow(
                icon: "person.text.rectangle.fill",
                title: "身份信息",
                value: "按页面提示填写"
            )
            GuidePreviewRow(
                icon: "faceid",
                title: "人脸核验",
                value: "本人操作"
            )
            GuidePreviewRow(
                icon: "lock.shield.fill",
                title: "资料保护",
                value: "仅用于审核"
            )
        }
    }

    private var loanApplicationPreview: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("借款金额")
                        .font(.system(size: 10))
                        .foregroundStyle(JYColor.tertiaryText)
                    Text("¥ 3,000")
                        .font(.custom("DINAlternate-Bold", size: 25))
                        .foregroundStyle(JYColor.ink)
                }
                Spacer()
                Text("示例数据")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: 0xF7903E))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xFFF4E8), in: Capsule())
            }

            HStack(spacing: 7) {
                ForEach(["3期", "6期", "12期"], id: \.self) { term in
                    Text(term)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(term == "6期" ? Color.white : JYColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            term == "6期" ? JYColor.action : Color.white,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                }
            }

            GuidePreviewRow(icon: "percent", title: "综合融资成本", value: "审批后展示")
            GuidePreviewRow(icon: "equal.circle.fill", title: "还款方式", value: "等额本息")

            Text("核对信息并提交申请")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(JYColor.action, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var billOverviewPreview: some View {
        VStack(spacing: 8) {
            HStack {
                Text("账单概览")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Spacer()
                Text("状态示意")
                    .font(.system(size: 9))
                    .foregroundStyle(JYColor.tertiaryText)
            }

            GuideBillStatusRow(period: "第1期", status: "已还款", color: JYColor.success)
            GuideBillStatusRow(period: "第2期", status: "待还款", color: JYColor.action)
            GuideBillStatusRow(period: "第3期", status: "未开始", color: JYColor.tertiaryText)
        }
    }

    private var billDetailPreview: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("第2期账单")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Spacer()
                Text("待还款")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(JYColor.action)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(JYColor.primarySoft, in: Capsule())
            }

            HStack(spacing: 7) {
                GuideBillMetric(title: "本期本金", value: "¥450.00")
                GuideBillMetric(title: "本期利息", value: "¥38.30")
                GuideBillMetric(title: "本期应还", value: "¥488.30", highlighted: true)
            }

            GuidePreviewRow(icon: "calendar", title: "到期日", value: "以账单页面为准")
            GuidePreviewRow(icon: "equal.circle.fill", title: "还款方式", value: "等额本息")
        }
    }

    private var headerIcon: String {
        switch kind {
        case .identity: return "person.crop.circle.badge.checkmark"
        case .loanApplication: return "slider.horizontal.3"
        case .billOverview, .billDetail: return "doc.text.fill"
        }
    }

    private var headerTitle: String {
        switch kind {
        case .identity: return "身份资料核验"
        case .loanApplication: return "借款方案"
        case .billOverview: return "我的账单"
        case .billDetail: return "账单详情"
        }
    }

    private var headerSubtitle: String {
        switch kind {
        case .identity: return "按页面提示逐步完成"
        case .loanApplication: return "确认金额、期限和费用"
        case .billOverview: return "查看每期还款状态"
        case .billDetail: return "核对本期还款构成"
        }
    }

    private var headerBadge: String {
        switch kind {
        case .identity: return "安全加密"
        case .loanApplication: return "示例数据"
        case .billOverview, .billDetail: return "状态示意"
        }
    }
}

private struct GuidePreviewRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JYColor.action)
                .frame(width: 28, height: 28)
                .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(JYColor.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(JYColor.ink)
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct GuideBillStatusRow: View {
    let period: String
    let status: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(period)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .frame(width: 46, height: 30)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("账单记录")
                .font(.system(size: 11))
                .foregroundStyle(JYColor.secondaryText)
            Spacer()
            Text(status)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1), in: Capsule())
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(JYColor.tertiaryText)
        }
    }
}

private struct GuideBillMetric: View {
    let title: String
    let value: String
    var highlighted = false

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(JYColor.tertiaryText)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(highlighted ? JYColor.action : JYColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(
            highlighted ? JYColor.primarySoft : Color.white,
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
    }
}

private struct GuideNoticeCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(JYColor.action)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JYColor.primarySoft.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GuideActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(JYColor.action, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
