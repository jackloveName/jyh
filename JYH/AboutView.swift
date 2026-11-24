import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero
                    positioning
                    serviceBoundary
                    partner
                    principles
                    riskNotice
                    support
                    legal
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .background(JYColor.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
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

            Text("关于我们")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Color.white)
    }

    private var hero: some View {
        VStack(spacing: 13) {
            BrandMark(size: 68)
                .padding(.top, 4)

            VStack(spacing: 5) {
                Text(AppConfig.appName)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(JYColor.ink)
                Text("助贷信息与申请流程服务")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(JYColor.action)
                Text(versionText)
                    .font(.system(size: 11))
                    .foregroundStyle(JYColor.tertiaryText)
            }

            HStack(spacing: 8) {
                AboutBadge(title: "申请服务", icon: "doc.text.fill")
                AboutBadge(title: "进度查询", icon: "clock.badge.checkmark")
                AboutBadge(title: "在线客服", icon: "headphones")
            }
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: 0xF2F7FF)],
                startPoint: .top,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var positioning: some View {
        AboutSectionCard(title: "平台定位", icon: "building.columns.fill") {
            Text("\(AppConfig.appName)为用户提供借款产品信息展示、申请资料提交、审核进度查询和相关客户服务。")
                .font(.system(size: 13))
                .foregroundStyle(JYColor.secondaryText)
                .lineSpacing(5)

            Text("平台不以自有资金直接发放贷款，也不代替合作机构作出授信决定。实际额度、期限、综合融资成本、审批结果及合同关系以合作机构确认和借款合同为准。")
                .font(.system(size: 13))
                .foregroundStyle(JYColor.ink)
                .lineSpacing(5)
        }
    }

    private var serviceBoundary: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("服务边界")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(JYColor.ink)

            AboutBoundaryCard(
                title: "平台负责",
                icon: "iphone.gen3",
                color: JYColor.action,
                items: [
                    "展示申请条件、费用及合作机构信息",
                    "承接资料填写、申请提交和状态查询",
                    "处理账户、流程及使用问题"
                ]
            )

            AboutBoundaryCard(
                title: "合作机构负责",
                icon: "checkmark.seal.fill",
                color: JYColor.success,
                items: [
                    "身份核验、风险评估和授信审批",
                    "确认最终额度、期限及综合融资成本",
                    "签订借款合同并处理放款、还款事项"
                ]
            )
        }
    }

    @ViewBuilder
    private var partner: some View {
        if let institution = store.currentLenderInstitution {
            AboutSectionCard(title: "合作机构", icon: "building.2.fill") {
                HStack(alignment: .top, spacing: 12) {
                    Text("合")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(JYColor.action)
                        .frame(width: 42, height: 42)
                        .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(institution.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(JYColor.ink)
                        Text("实际合作机构、放款主体及合同关系以申请页面展示和最终签署的合同为准。")
                            .font(.system(size: 11))
                            .foregroundStyle(JYColor.secondaryText)
                            .lineSpacing(3)
                    }
                }

                NavigationLink(value: AppRoute.lenders) {
                    HStack {
                        Text("查看全部合作机构")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(JYColor.action)
                    .frame(height: 34)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var principles: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("服务原则")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(JYColor.ink)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                AboutPrincipleCard(icon: "person.badge.shield.checkmark.fill", title: "真实申请", message: "资料由本人提交并保持真实有效")
                AboutPrincipleCard(icon: "doc.text.magnifyingglass", title: "费用透明", message: "费用与合同信息以页面展示为准")
                AboutPrincipleCard(icon: "lock.shield.fill", title: "隐私保护", message: "在授权范围内处理个人信息")
                AboutPrincipleCard(icon: "hand.raised.fill", title: "理性借贷", message: "结合收入与负债情况审慎申请")
            }
        }
    }

    private var riskNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: 0xF7903E))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                Text("重要提示")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text("提交申请不代表审批通过或已经放款。请勿向任何个人支付所谓审核费、保证金或解冻费。逾期可能产生合同约定费用并影响信用记录。")
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xFFF7EE), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var support: some View {
        NavigationLink(value: AppRoute.support) {
            HStack(spacing: 11) {
                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 3) {
                    Text("联系在线客服")
                        .font(.system(size: 15, weight: .semibold))
                    Text("账户、申请、审核或使用问题均可咨询")
                        .font(.system(size: 11))
                        .opacity(0.82)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 66)
            .background(
                LinearGradient(
                    colors: [JYColor.action, Color(hex: 0x3D91F3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
        }
        .buttonStyle(PressScaleStyle())
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: AppRoute.userAgreement) {
                legalRow(title: "用户协议")
            }
            .buttonStyle(PressScaleStyle())
            Divider().overlay(JYColor.divider)
            NavigationLink(value: AppRoute.privacyPolicy) {
                legalRow(title: "隐私政策")
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func legalRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(JYColor.ink)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(JYColor.tertiaryText)
        }
        .frame(height: 48)
        .contentShape(Rectangle())
    }

    private var footer: some View {
        VStack(spacing: 5) {
            Text("\(AppConfig.appName) · \(versionText)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(JYColor.tertiaryText)
            Text(JYCopy.approvalDisclosure)
                .font(.system(size: 10))
                .foregroundStyle(JYColor.tertiaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let versionValue = version ?? "1.0"
        if let build, !build.isEmpty {
            return "版本 \(versionValue)（\(build)）"
        }
        return "版本 \(versionValue)"
    }
}

private struct AboutSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JYColor.action)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AboutBadge: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(title)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(JYColor.action)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white, in: Capsule())
    }
}

private struct AboutBoundaryCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 12))
                        .foregroundStyle(JYColor.secondaryText)
                        .lineSpacing(3)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct AboutPrincipleCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(JYColor.action)
                .frame(width: 36, height: 36)
                .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(JYColor.ink)
            Text(message)
                .font(.system(size: 10))
                .foregroundStyle(JYColor.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}
