import SwiftUI

struct HelpCenterView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory = .all
    @State private var expandedArticleID: String?

    private var filteredArticles: [HelpArticle] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return HelpArticle.all.filter { article in
            let matchesCategory = selectedCategory == .all || article.category == selectedCategory
            guard !keyword.isEmpty else { return matchesCategory }
            let searchable = [
                article.question,
                article.summary,
                article.details.joined(separator: " "),
                article.steps.joined(separator: " ")
            ].joined(separator: " ").lowercased()
            return searchable.contains(keyword)
        }
    }

    private var applicationEntryRoute: AppRoute {
        store.storedLoanApplication == nil ? .loanFlow : .h5LoanResult
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    searchField
                    quickActions
                    categoryPicker
                    articleSection
                    supportCard
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
        .jyDismissKeyboardOnBackgroundTap()
        .jyKeyboardDoneButton()
        .onChange(of: searchText) { _, value in
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                selectedCategory = .all
                expandedArticleID = nil
            }
        }
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

            Text("帮助中心")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Color.white)
    }

    private var heroCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        colors: [JYColor.action, Color(hex: 0x54A2F7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("常见问题与操作指引")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JYColor.ink)
                Text("先查找答案，仍有疑问可转在线客服。")
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(17)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: 0xF2F7FF)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(JYColor.tertiaryText)

            TextField("搜索登录、认证、审核、账单等问题", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(JYColor.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(JYColor.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清空搜索")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color(hex: 0xE8EDF4), lineWidth: 1)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            NavigationLink(value: store.isLoggedIn ? AppRoute.h5Bill : AppRoute.safety) {
                quickActionLabel(icon: "doc.text.fill", title: "查看账单")
            }
            .buttonStyle(PressScaleStyle())

            NavigationLink(value: applicationEntryRoute) {
                quickActionLabel(
                    icon: store.storedLoanApplication == nil ? "square.and.pencil" : "clock.badge.checkmark",
                    title: store.storedLoanApplication == nil ? "申请借款" : "申请进度"
                )
            }
            .buttonStyle(PressScaleStyle())

            NavigationLink(value: AppRoute.support) {
                quickActionLabel(icon: "headphones", title: "在线客服")
            }
            .buttonStyle(PressScaleStyle())
        }
    }

    private func quickActionLabel(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.action)
                .frame(width: 38, height: 38)
                .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JYColor.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HelpCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                            expandedArticleID = nil
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(category.title)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(
                            selectedCategory == category ? Color.white : JYColor.secondaryText
                        )
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(
                            selectedCategory == category ? JYColor.action : Color.white,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
        }
    }

    private var articleSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(searchText.isEmpty ? "常见问题" : "搜索结果")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Spacer()
                Text("\(filteredArticles.count) 个问题")
                    .font(.system(size: 11))
                    .foregroundStyle(JYColor.tertiaryText)
            }

            if filteredArticles.isEmpty {
                ContentUnavailableView {
                    Label("没有找到相关问题", systemImage: "magnifyingglass")
                } description: {
                    Text("可以换一个关键词，或直接联系在线客服。")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredArticles) { article in
                        HelpArticleCard(
                            article: article,
                            isExpanded: expandedArticleID == article.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedArticleID = expandedArticleID == article.id ? nil : article.id
                            }
                        }
                    }
                }
            }
        }
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(JYColor.action)
                VStack(alignment: .leading, spacing: 3) {
                    Text("仍然没有解决？")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(JYColor.ink)
                    Text("可把遇到的问题、发生时间和页面提示发给在线客服。")
                        .font(.system(size: 12))
                        .foregroundStyle(JYColor.secondaryText)
                        .lineSpacing(3)
                }
            }

            NavigationLink(value: AppRoute.support) {
                Text("联系在线客服")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(JYColor.action, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private enum HelpCategory: String, CaseIterable, Identifiable {
    case all
    case account
    case identity
    case loan
    case review
    case bill
    case privacy
    case service

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .account: return "账户安全"
        case .identity: return "实名认证"
        case .loan: return "借款申请"
        case .review: return "审核额度"
        case .bill: return "账单还款"
        case .privacy: return "隐私协议"
        case .service: return "客服反馈"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .account: return "person.crop.circle.badge.checkmark"
        case .identity: return "person.text.rectangle.fill"
        case .loan: return "doc.text.fill"
        case .review: return "clock.badge.checkmark.fill"
        case .bill: return "calendar.badge.clock"
        case .privacy: return "lock.shield.fill"
        case .service: return "headphones"
        }
    }
}

private struct HelpArticle: Identifiable {
    let category: HelpCategory
    let question: String
    let summary: String
    var details: [String] = []
    var steps: [String] = []

    var id: String { question }
}

private extension HelpArticle {
    static let all: [HelpArticle] = [
        HelpArticle(
            category: .account,
            question: "收不到登录验证码怎么办？",
            summary: "先确认手机号、网络和短信拦截状态，再尝试重新获取。",
            steps: [
                "确认输入的手机号与当前账户一致，并检查是否有空格或漏输。",
                "查看手机短信垃圾箱、拦截记录，确认手机信号及停机状态正常。",
                "短时间内不要连续多次获取验证码，间隔后再重试。",
                "仍无法收到时，联系在线客服核对账户状态。"
            ]
        ),
        HelpArticle(
            category: .account,
            question: "为什么登录后提示登录状态已失效？",
            summary: "登录凭证过期、在其他设备重新登录或长时间未操作都可能触发重新登录。",
            details: [
                "为保护账户安全，凭证失效后系统会要求重新验证。重新登录不会收取费用，也不会影响正在审核的申请。"
            ],
            steps: [
                "返回登录页，使用验证码或密码重新登录。",
                "不要向任何人转发收到的验证码。",
                "如果频繁失效，记录提示文字并联系在线客服。"
            ]
        ),
        HelpArticle(
            category: .account,
            question: "有人自称平台客服，让我转账或提供验证码怎么办？",
            summary: "不要转账、不要提供密码或验证码，先通过 App 内客服核实。",
            details: [
                "正规客服不会要求你通过私人账户缴纳保证金、解冻费或审核费，也不会索要登录密码和短信验证码。"
            ],
            steps: [
                "立即停止与对方沟通，不要点击陌生链接或下载来源不明的应用。",
                "退出可疑页面，从 App 内重新进入官方客服。",
                "如已产生资金风险，请及时保留凭证并联系警方。"
            ]
        ),
        HelpArticle(
            category: .account,
            question: "如何修改登录密码？",
            summary: "登录后进入“我的-设置-修改登录密码”完成身份验证。",
            steps: [
                "打开“我的”页面并进入设置。",
                "选择“修改登录密码”，按提示完成验证码验证。",
                "设置符合要求的新密码，修改成功后重新登录。"
            ]
        ),
        HelpArticle(
            category: .identity,
            question: "身份证照片一直上传失败是什么原因？",
            summary: "常见原因是反光、边缘缺失、照片模糊或证件已过期。",
            steps: [
                "在光线均匀的位置拍摄，避免闪光灯反光或阴影遮挡。",
                "确保身份证四角完整、文字清晰，不在照片上添加水印。",
                "确认证件在有效期内，且拍摄的是本人证件原件。",
                "连续失败时，退出重进后重新尝试或联系在线客服。"
            ]
        ),
        HelpArticle(
            category: .identity,
            question: "人脸识别多次不通过怎么办？",
            summary: "请由本人操作，并保持光线充足、面部无遮挡。",
            steps: [
                "摘除帽子、口罩和遮挡面部的物品。",
                "在光线正常的环境中进行，避免背光或屏幕强光直射。",
                "按页面提示完成眨眼、转头等动作，不要离镜头过近。",
                "如仍失败，检查系统相机权限后重试。"
            ]
        ),
        HelpArticle(
            category: .identity,
            question: "实名认证信息填写错误还能修改吗？",
            summary: "已提交的实名信息不能自行反复修改，需要先核对当前认证状态。",
            details: [
                "姓名和证件号码必须与本人有效证件一致。错误信息可能导致认证失败或后续审核无法继续。"
            ],
            steps: [
                "返回实名认证页面查看当前是否仍在审核。",
                "不要重复提交不同身份信息。",
                "如确认填写错误，请联系在线客服说明具体情况。"
            ]
        ),
        HelpArticle(
            category: .identity,
            question: "认证资料提交后多久能完成？",
            summary: "资料校验通常很快，人工核验或风险审核可能需要更长时间。",
            details: [
                "页面会展示当前认证步骤或审核状态。请以页面最新状态为准，不要重复提交多份不同资料。"
            ]
        ),
        HelpArticle(
            category: .loan,
            question: "这个平台是直接放款的贷款机构吗？",
            summary: "本平台提供助贷信息与申请流程服务，实际审批和借款关系由合作机构完成。",
            details: [
                "申请页面会展示实际合作出借机构。额度、期限、综合融资成本、审批结果及合同关系均以合作机构最终确认为准。"
            ]
        ),
        HelpArticle(
            category: .loan,
            question: "提交借款申请前需要准备什么？",
            summary: "需要准备本人有效身份证、常用手机号及审核所需的真实申请资料。",
            steps: [
                "完成本人实名认证和人脸核验。",
                "核对职业、收入、联系信息等资料是否真实完整。",
                "阅读费用说明、合作机构信息和相关协议。",
                "根据还款能力选择合理的金额与期限。"
            ]
        ),
        HelpArticle(
            category: .loan,
            question: "为什么金额或期限无法选择？",
            summary: "可选项受账户认证状态、产品范围和页面当前状态限制。",
            details: [
                "如已有审核中或未通过的申请，系统会优先展示已有申请状态，不会重新开放新的申请配置。"
            ]
        ),
        HelpArticle(
            category: .loan,
            question: "提交申请后为什么只显示“审核中”？",
            summary: "申请已提交成功，正在等待页面状态更新。",
            steps: [
                "返回首页查看申请状态卡片。",
                "点击状态卡片进入申请详情，核对金额、期限和合作机构。",
                "等待页面显示预计更新结果，不要重复提交。",
                "超过预计时间仍未更新时，可联系在线客服。"
            ]
        ),
        HelpArticle(
            category: .review,
            question: "申请提交后多久出结果？",
            summary: "结果时间会受资料完整度、申请时段和合作机构审核进度影响。",
            details: [
                "请以首页状态卡片或申请详情页的实时更新为准。保持页面网络正常，无需重复提交。"
            ]
        ),
        HelpArticle(
            category: .review,
            question: "为什么本次申请未通过后没有再次提交按钮？",
            summary: "本次申请结果已结束，页面会保留结果和申请信息供查看。",
            details: [
                "系统不会通过重复提交来改变本次审核结果。你可以查看申请详情，后续服务信息如有更新，会通过页面提示。"
            ]
        ),
        HelpArticle(
            category: .review,
            question: "申请未通过后，可借额度为什么不见了？",
            summary: "申请结果更新后，页面会隐藏参考额度，避免把历史参考值误认为当前可借金额。",
            details: [
                "首页和“我的”会统一显示“暂不可借”和本次申请结果，不再展示可借数字。"
            ]
        ),
        HelpArticle(
            category: .review,
            question: "首页和“我的”显示的额度为什么应该一致？",
            summary: "两个页面现在使用同一份额度数据，仅展示方式不同。",
            details: [
                "首页展示参考额度，“我的”按隐私要求只保留前两位并隐藏其余数字。底层金额和计算来源保持一致。"
            ]
        ),
        HelpArticle(
            category: .review,
            question: "完成认证后一定会获得额度吗？",
            summary: "完成认证只是进入评估的前提，不代表一定获得额度或审批通过。",
            details: [
                "额度与审核结果会结合资料完整性、合作机构规则及实际审批情况确定。"
            ]
        ),
        HelpArticle(
            category: .bill,
            question: "申请通过后为什么暂时没有账单？",
            summary: "账单通常在合作机构完成放款并生成还款计划后出现。",
            details: [
                "仅提交申请或审核通过但尚未放款时，可能暂时没有账单。具体放款及还款安排以合作机构记录为准。"
            ]
        ),
        HelpArticle(
            category: .bill,
            question: "账单中的本期应还是怎么计算的？",
            summary: "通常由本期本金、利息及合同约定费用组成。",
            details: [
                "实际金额以借款合同、费用明示表和合作机构生成的账单为准。如发现页面金额与合同不一致，请保留截图并联系在线客服。"
            ]
        ),
        HelpArticle(
            category: .bill,
            question: "在 App 的哪里查看账单？",
            summary: "可从首页或“我的”进入账单页面。",
            steps: [
                "进入“我的”页面。",
                "点击“我的账单”快捷入口。",
                "选择对应期数，查看本金、利息、应还金额和状态。"
            ]
        ),
        HelpArticle(
            category: .bill,
            question: "还款失败或页面状态没有更新怎么办？",
            summary: "先确认合作机构渠道是否扣款成功，避免重复操作。",
            steps: [
                "保留合作机构页面的处理结果或扣款凭证。",
                "等待页面状态同步，不要连续重复操作。",
                "确认已扣款但账单未更新时，联系在线客服核对。"
            ]
        ),
        HelpArticle(
            category: .bill,
            question: "可以提前还款吗？",
            summary: "是否支持及费用如何计算，以实际借款合同和合作机构规则为准。",
            details: [
                "提前还款可能涉及当期利息、手续费或其他合同约定费用。操作前请先查看合同及合作机构页面说明。"
            ]
        ),
        HelpArticle(
            category: .bill,
            question: "逾期会有什么影响？",
            summary: "逾期可能产生合同约定费用，并影响后续服务及信用记录。",
            details: [
                "如预计无法按期还款，应尽早查看合同中的逾期规则，并通过官方客服了解可处理方式。不要相信付费“修复征信”或“消除逾期”的私下承诺。"
            ]
        ),
        HelpArticle(
            category: .privacy,
            question: "为什么需要身份证和人脸信息？",
            summary: "用于确认申请人身份、完成实名认证和满足合作机构风险审核要求。",
            details: [
                "平台会按照隐私政策处理相关信息。请确认操作环境安全，不要向第三方转发认证页面或验证码。"
            ]
        ),
        HelpArticle(
            category: .privacy,
            question: "申请资料会提供给合作机构吗？",
            summary: "为完成审批，必要信息可能依法提供给页面展示的合作机构。",
            details: [
                "具体共享范围、目的和处理规则以申请授权及《隐私政策》为准。申请前请完整阅读相关协议。"
            ]
        ),
        HelpArticle(
            category: .privacy,
            question: "如何注销账户或处理个人信息？",
            summary: "可在账户设置查看注销入口，或通过在线客服提出信息处理请求。",
            details: [
                "如果存在未完成申请、还款或其他合同事项，注销前需要先核对相关状态。具体处理范围以隐私政策及适用规则为准。"
            ]
        ),
        HelpArticle(
            category: .service,
            question: "怎样联系在线客服？",
            summary: "首页、“我的”页面和帮助中心均提供在线客服入口。",
            steps: [
                "从当前页面点击“在线客服”或“咨询”。",
                "描述遇到问题的页面和提示文字。",
                "不要发送密码、验证码或完整证件照片。"
            ]
        ),
        HelpArticle(
            category: .service,
            question: "客服一般多久回复？",
            summary: "在线时会尽快回复，离线时可先留言，后续进入页面查看消息。",
            details: [
                "客服消息会保留最近记录。涉及审核或资金处理的问题，请提供必要的时间、页面提示和问题描述。"
            ]
        ),
        HelpArticle(
            category: .service,
            question: "如何提交产品或功能意见？",
            summary: "可通过在线客服提交建议，并说明使用场景和遇到的问题。",
            details: [
                "建议尽量描述具体页面、操作步骤和期望效果。不要附带与问题无关的身份证、联系人或账户敏感信息。"
            ]
        )
    ]
}

private struct HelpArticleCard: View {
    let article: HelpArticle
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: article.category.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(JYColor.action)
                        .frame(width: 30, height: 30)
                        .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.question)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(JYColor.ink)
                            .multilineTextAlignment(.leading)
                        Text(article.summary)
                            .font(.system(size: 11))
                            .foregroundStyle(JYColor.secondaryText)
                            .lineSpacing(3)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 5)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JYColor.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(.top, 8)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(article.details, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.system(size: 12))
                            .foregroundStyle(JYColor.secondaryText)
                            .lineSpacing(4)
                    }

                    if !article.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("可以这样处理")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(JYColor.ink)

                            ForEach(Array(article.steps.enumerated()), id: \.offset) { index, step in
                                HelpAnswerStep(number: index + 1, text: step)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 15)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct HelpAnswerStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(number)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(JYColor.action)
                .frame(width: 20, height: 20)
                .background(JYColor.primarySoft, in: Circle())
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(JYColor.secondaryText)
                .lineSpacing(3)
        }
    }
}
