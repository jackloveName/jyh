import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var trialAmountText = String(JinyinghuaLoanConfig.randomDefaultAmount())
    @State private var trialTermMonths = JinyinghuaLoanConfig.defaultTermMonths

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 390
            let contentShift = usesLoanTrial ? 70.0 : 0
            let quotaHeight = 320.0 + contentShift
            let applicationShift = store.storedLoanApplication == nil ? 0.0 : 116.0

            ScrollView {
                ZStack(alignment: .topLeading) {
                    JYColor.canvas

                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: 0x086CF5), location: 0),
                            .init(color: Color(hex: 0x0D75F0), location: 0.14),
                            .init(color: Color(hex: 0x147AF2), location: 0.36),
                            .init(color: Color(hex: 0x3D94F7), location: 0.57),
                            .init(color: Color(hex: 0x85BFFC), location: 0.73),
                            .init(color: Color(hex: 0xC9E2FC), location: 0.87),
                            .init(color: JYColor.canvas, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: 280 * scale)

                    header(scale: scale)
                    quotaCard(scale: scale)
                        .frame(width: 358 * scale, height: quotaHeight * scale)
                        .position(x: 195 * scale, y: (135 + quotaHeight / 2) * scale)
                    if store.storedLoanApplication != nil {
                        applicationStatusCard(scale: scale)
                            .frame(width: 358 * scale, height: 100 * scale)
                            .position(x: 195 * scale, y: (523 + contentShift) * scale)
                    }
                    stepsCard(scale: scale)
                        .frame(width: 358 * scale, height: 106 * scale)
                        .position(x: 195 * scale, y: (524 + contentShift + applicationShift) * scale)
                    supportCard(scale: scale)
                        .frame(width: 356 * scale, height: 54 * scale)
                        .position(x: 195 * scale, y: (618 + contentShift + applicationShift) * scale)
                    benefitCard(scale: scale)
                        .frame(width: 358 * scale, height: 92 * scale)
                        .position(x: 195 * scale, y: (706 + contentShift + applicationShift) * scale)
                    guideSection(scale: scale)
                        .frame(width: 358 * scale, height: 176 * scale)
                        .position(x: 195 * scale, y: (852 + contentShift + applicationShift) * scale)

                    VStack(spacing: 2 * scale) {
                        Text(JYCopy.approvalDisclosure)
                        if let disclosure = store.providerDisclosure {
                            NavigationLink(value: AppRoute.lenders) {
                                HStack(spacing: 5 * scale) {
                                    ProviderShieldIcon(scale: scale)
                                    Text(disclosure)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 8 * scale, weight: .bold))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("查看合作机构")
                        }
                    }
                    .font(.system(size: 11 * scale))
                    .foregroundStyle(JYColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(width: 326 * scale)
                    .position(x: 195 * scale, y: (968 + contentShift + applicationShift) * scale)
                }
                .frame(
                    width: proxy.size.width,
                    height: (1_018 + contentShift + applicationShift) * scale,
                    alignment: .top
                )
            }
            .scrollIndicators(.hidden)
            .background(JYColor.canvas.ignoresSafeArea())
        }
        .ignoresSafeArea(edges: .top)
        .jyDismissKeyboardOnBackgroundTap()
        .jyKeyboardDoneButton()
        .refreshable {
            if store.isLoggedIn {
                await store.refreshAll()
            }
        }
        .onAppear {
            guard store.isLoggedIn else { return }
            Task {
                await store.loadStoredLoanApplicationIfNeeded()
            }
        }
        .task(id: store.storedLoanApplication?.reviewDeadlineAt) {
            guard let application = store.storedLoanApplication,
                  application.isReviewing,
                  let deadline = application.reviewDeadlineAt else {
                return
            }
            let delay = deadline.timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            await store.loadStoredLoanApplicationIfNeeded()
        }
        .navigationBarBackButtonHidden()
    }

    private func header(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 9 * scale) {
                Text(AppConfig.appName)
                    .font(.system(size: 22 * scale, weight: .bold))
                    .foregroundStyle(.white)
                Text("便捷资金周转服务")
                    .font(.system(size: 14 * scale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .frame(width: 250 * scale, alignment: .leading)
            .position(x: 147 * scale, y: 96 * scale)
        }
    }

    private func quotaCard(scale: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(Color.white)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8 * scale) {
                    Text(store.quotaReferenceLabel)
                        .font(.system(size: 13 * scale, weight: .medium))
                        .foregroundStyle(JYColor.secondaryText)

                    Spacer()

                    Text(store.quotaStatusText)
                        .font(.system(size: 11 * scale, weight: .semibold))
                        .foregroundStyle(quotaStatusColor)
                        .padding(.horizontal, 9 * scale)
                        .padding(.vertical, 5 * scale)
                        .background(quotaStatusColor.opacity(0.1), in: Capsule())
                }

                Text(store.quotaDisplayText)
                    .font(
                        store.hasRejectedBorrowApplication
                            ? .system(size: 36 * scale, weight: .semibold)
                            : .custom("DINAlternate-Bold", size: 58 * scale)
                    )
                    .foregroundStyle(JYColor.ink)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .scaleEffect(x: 0.94, y: 1, anchor: .leading)
                    .padding(.top, 1 * scale)

                if usesLoanTrial {
                    loanTrialSection(scale: scale)
                        .padding(.top, 8 * scale)
                } else {
                    VStack(alignment: .leading, spacing: 7 * scale) {
                        HStack {
                            Text(store.isLoggedIn
                                ? "认证进度 \(completedKYCStepCount)/\(totalKYCStepCount)"
                                : "登录后开始认证")
                                .font(.system(size: 12 * scale, weight: .medium))
                                .foregroundStyle(JYColor.secondaryText)

                            Spacer()

                            Text(store.kycNextStep.actionTitle)
                                .font(.system(size: 11 * scale, weight: .medium))
                                .foregroundStyle(JYColor.action)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(hex: 0xE9EEF5))

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [JYColor.primary, JYColor.primaryDeep],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * kycProgressValue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 6 * scale)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8 * scale)
                }

                HStack(spacing: 0) {
                    quotaMetric(title: "借款期限", value: "3/6/12期", scale: scale)
                    metricDivider(scale: scale)
                    quotaMetric(title: "还款方式", value: "等额本息", scale: scale)
                    metricDivider(scale: scale)
                    quotaMetric(title: "年化成本", value: "最高24%", scale: scale)
                }
                .padding(.top, 14 * scale)

                HStack(spacing: 5 * scale) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12 * scale))
                    Text(store.quotaDescriptionText)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.system(size: 11 * scale, weight: .medium))
                .foregroundStyle(JYColor.secondaryText)
                .padding(.top, 12 * scale)

                Spacer(minLength: 10 * scale)

                applyControl(scale: scale)
                    .frame(height: 54 * scale)
            }
            .padding(.horizontal, 16 * scale)
            .padding(.vertical, 16 * scale)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func quotaMetric(title: String, value: String, scale: CGFloat) -> some View {
        VStack(spacing: 5 * scale) {
            Text(title)
                .font(.system(size: 11 * scale))
                .foregroundStyle(JYColor.tertiaryText)
            Text(value)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
    }

    private func applicationStatusCard(scale: CGFloat) -> some View {
        let application = store.storedLoanApplication
        let rejected = application?.isRejected == true
        let approved = application?.isApproved == true
        let color = rejected
            ? JYColor.danger
            : (approved ? JYColor.success : Color(hex: 0xF7903E))
        let icon = rejected
            ? "xmark.circle.fill"
            : (approved ? "checkmark.circle.fill" : "clock.fill")
        let title = rejected
            ? "本次申请未通过"
            : (approved ? "借款申请已通过" : "借款申请审核中")

        return NavigationLink(value: AppRoute.h5LoanResult) {
            HStack(spacing: 13 * scale) {
                Image(systemName: icon)
                    .font(.system(size: 22 * scale, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 42 * scale, height: 42 * scale)
                    .background(color.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 5 * scale) {
                    Text(title)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(JYColor.ink)

                    Text(applicationDetailText(application))
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(JYColor.secondaryText)
                        .lineLimit(2)
                        .lineSpacing(3 * scale)
                }

                Spacer()

                if let application {
                    VStack(alignment: .trailing, spacing: 6 * scale) {
                        Text(application.principal.amountString)
                            .font(.custom("DINAlternate-Bold", size: 20 * scale))
                            .foregroundStyle(rejected ? JYColor.danger : JYColor.ink)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10 * scale, weight: .bold))
                            .foregroundStyle(JYColor.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, 15 * scale)
            .padding(.vertical, 16 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(
            rejected
                ? "查看未通过的借款申请详情"
                : (approved ? "查看已通过的借款申请详情" : "查看审核中的借款申请详情")
        )
    }

    private func applicationDetailText(_ application: StoredLoanApplication?) -> String {
        guard let application else { return "" }
        if application.isRejected {
            return "感谢您的申请，本次结果已更新，请留意后续服务信息"
        }
        if application.isApproved {
            return "借款申请已通过，可前往“我的账单”查看还款安排"
        }
        guard let deadline = application.reviewDeadlineAt else {
            return "资料已提交，请等待审核结果"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return "资料已提交，预计 \(formatter.string(from: deadline)) 前完成审核"
    }

    private func metricDivider(scale: CGFloat) -> some View {
        Rectangle()
            .fill(Color(hex: 0xEEF2F7))
            .frame(width: 1, height: 28 * scale)
    }

    private var quotaStatusColor: Color {
        if store.hasRejectedBorrowApplication { return Color(hex: 0xF7903E) }
        if !store.isLoggedIn { return JYColor.action }
        return store.quotaNeedsEvaluation ? Color(hex: 0xF7903E) : JYColor.success
    }

    private var completedKYCStepCount: Int {
        guard store.isLoggedIn else { return 0 }
        if store.kycSteps.isEmpty {
            return store.isRealNameVerified ? 1 : 0
        }
        return min(store.kycSteps.filter { $0.status == "2" }.count, totalKYCStepCount)
    }

    private var totalKYCStepCount: Int {
        max(store.kycSteps.count, 3)
    }

    private var kycProgressValue: CGFloat {
        guard totalKYCStepCount > 0 else { return 0 }
        return CGFloat(completedKYCStepCount) / CGFloat(totalKYCStepCount)
    }

    private var usesLoanTrial: Bool {
        store.isLoggedIn && store.kycNextStep == .loanReady
    }

    private var trialAmount: Int? {
        let amount = Int(trialAmountText) ?? 0
        guard (JinyinghuaLoanConfig.minAmount...JinyinghuaLoanConfig.maxAmount).contains(amount) else {
            return nil
        }
        return amount
    }

    private var trialCalculation: JinyinghuaLoanCalculation? {
        guard let trialAmount else { return nil }
        return JinyinghuaLoanCalculator.calculate(
            principal: trialAmount,
            termMonths: trialTermMonths
        )
    }

    private func loanTrialSection(scale: CGFloat) -> some View {
        VStack(spacing: 8 * scale) {
            HStack {
                Label("认证已完成", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11 * scale, weight: .semibold))
                    .foregroundStyle(JYColor.success)
                Spacer()
                Text("借款试算")
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text("仅作费用说明")
                    .font(.system(size: 10 * scale))
                    .foregroundStyle(JYColor.tertiaryText)
            }

            HStack(spacing: 10 * scale) {
                HStack(spacing: 2 * scale) {
                    Button {
                        adjustTrialAmount(by: -JinyinghuaLoanConfig.amountStep)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10 * scale, weight: .bold))
                            .frame(width: 24 * scale, height: 30 * scale)
                    }
                    .buttonStyle(PressScaleStyle())

                    Text("¥")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(JYColor.secondaryText)

                    TextField("金额", text: $trialAmountText)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(JYColor.ink)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 44 * scale)
                        .onChange(of: trialAmountText) { _, value in
                            let digits = String(value.filter(\.isNumber).prefix(4))
                            if digits != value {
                                trialAmountText = digits
                            }
                        }

                    Button {
                        adjustTrialAmount(by: JinyinghuaLoanConfig.amountStep)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10 * scale, weight: .bold))
                            .frame(width: 24 * scale, height: 30 * scale)
                    }
                    .buttonStyle(PressScaleStyle())
                }
                .padding(.horizontal, 4 * scale)
                .frame(maxWidth: .infinity)
                .frame(height: 32 * scale)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                        .stroke(Color(hex: 0xDCE5F0), lineWidth: 1)
                }

                HStack(spacing: 4 * scale) {
                    ForEach(JinyinghuaLoanConfig.termMonthsOptions, id: \.self) { term in
                        Button {
                            trialTermMonths = term
                        } label: {
                            Text("\(term)期")
                                .font(.system(size: 11 * scale, weight: .semibold))
                                .foregroundStyle(trialTermMonths == term ? .white : JYColor.secondaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 30 * scale)
                                .background(
                                    trialTermMonths == term ? JYColor.action : Color.white,
                                    in: RoundedRectangle(cornerRadius: 7 * scale, style: .continuous)
                                )
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
                .padding(1 * scale)
                .frame(width: 148 * scale, height: 32 * scale)
                .background(Color(hex: 0xE9EEF5), in: RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
            }

            HStack(spacing: 8 * scale) {
                if let trialCalculation {
                    Text("每期 ¥\(trialCalculation.monthlyPayment.moneyString)")
                    Spacer()
                    Text("总费用 ¥\(trialCalculation.totalInterest.moneyString)")
                } else {
                    Text("请输入1,000–8,000元")
                        .foregroundStyle(Color(hex: 0xD97706))
                    Spacer()
                    Text("金额需为100元整数倍")
                }
            }
            .font(.system(size: 11 * scale, weight: .medium))
            .foregroundStyle(JYColor.secondaryText)
        }
        .padding(10 * scale)
        .background(Color(hex: 0xF6F8FB), in: RoundedRectangle(cornerRadius: 10 * scale, style: .continuous))
    }

    private func adjustTrialAmount(by delta: Int) {
        let parsed = Int(trialAmountText) ?? JinyinghuaLoanConfig.minAmount
        let current = min(
            JinyinghuaLoanConfig.maxAmount,
            max(JinyinghuaLoanConfig.minAmount, parsed)
        )
        let next = min(
            JinyinghuaLoanConfig.maxAmount,
            max(JinyinghuaLoanConfig.minAmount, current + delta)
        )
        trialAmountText = String(next)
    }

    @ViewBuilder
    private func applyControl(scale: CGFloat) -> some View {
        if let application = store.storedLoanApplication {
            NavigationLink(value: AppRoute.h5LoanResult) {
                HStack(spacing: 7 * scale) {
                    Image(systemName: applicationActionIcon(application))
                        .font(.system(size: 13 * scale, weight: .semibold))
                    Text(applicationActionTitle(application))
                        .font(.system(size: 14 * scale, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9 * scale, weight: .bold))
                }
                .foregroundStyle(applicationActionColor(application))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    applicationActionColor(application).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                )
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(applicationActionTitle(application))
        } else if store.isLoggedIn {
            NavigationLink(value: store.kycActionRoute) {
                applyButtonLabel(store.kycNextStep.actionTitle, scale: scale)
            }
            .buttonStyle(PressScaleStyle())
        } else {
            Button {
                store.requestLogin()
            } label: {
                applyButtonLabel("立即申请", scale: scale)
            }
            .buttonStyle(PressScaleStyle())
        }
    }

    private func applicationActionTitle(_ application: StoredLoanApplication) -> String {
        if application.isRejected { return "查看申请结果" }
        if application.isApproved { return "查看借款详情" }
        return "查看审核进度"
    }

    private func applicationActionIcon(_ application: StoredLoanApplication) -> String {
        if application.isRejected { return "xmark.circle.fill" }
        if application.isApproved { return "checkmark.seal.fill" }
        return "clock.fill"
    }

    private func applicationActionColor(_ application: StoredLoanApplication) -> Color {
        if application.isRejected { return Color(hex: 0xD96B45) }
        if application.isApproved { return JYColor.success }
        return JYColor.action
    }

    private func applyButtonLabel(_ title: String, scale: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 15 * scale, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                    .fill(JYColor.action)
            )
    }

    private func stepsCard(scale: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(Color.white)

            HStack(spacing: 0) {
                stepContent(
                    asset: "figma-home-step-1",
                    title: "实名认证",
                    subtitle: "身份核验",
                    scale: scale
                )
                stepContent(
                    asset: "figma-home-step-2",
                    title: "完善资料",
                    subtitle: "额度评估",
                    scale: scale
                )
                stepContent(
                    asset: "figma-home-step-3",
                    title: "提交申请",
                    subtitle: "结果通知",
                    scale: scale
                )
            }
            .padding(.horizontal, 20 * scale)
            .frame(height: 106 * scale, alignment: .top)
        }
    }

    private func stepContent(asset: String, title: String, subtitle: String, scale: CGFloat) -> some View {
        VStack(spacing: 3 * scale) {
            Image(asset)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 34 * scale, height: 34 * scale)
            Text(title)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(JYColor.ink)
            Text(subtitle)
                .font(.system(size: 12 * scale))
                .foregroundStyle(JYColor.secondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 13 * scale)
    }

    private func supportCard(scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            Image("figma-home-support")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 29 * scale, height: 29 * scale)

            VStack(alignment: .leading, spacing: 2 * scale) {
                Text("在线客服")
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text("申请疑问，可咨询在线客服")
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(JYColor.secondaryText)
            }
            .padding(.leading, 16 * scale)

            Spacer()

            NavigationLink(value: AppRoute.support) {
                Text("咨询")
                    .font(.system(size: 12 * scale, weight: .medium))
                    .foregroundStyle(JYColor.action)
                    .frame(width: 47 * scale, height: 22 * scale)
                    .background(JYColor.primarySoft, in: Capsule())
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.leading, 26 * scale)
        .padding(.trailing, 17 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
    }

    private func benefitCard(scale: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, Color(hex: 0xFFF8F1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Image("figma-home-benefit-art")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: 102 * scale, height: 88 * scale)
                .clipped()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 3 * scale)

            VStack(alignment: .leading, spacing: 4 * scale) {
                Text("借款费用提示")
                    .font(.system(size: 16 * scale, weight: .bold))
                    .foregroundStyle(JYColor.ink)
                Text(JYCopy.rateDisclosure)
                    .font(.system(size: 13 * scale, weight: .medium))
                    .foregroundStyle(Color(hex: 0xFF7A45))
            }
            .padding(.leading, 27 * scale)
        }
    }

    private func guideSection(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(Color.white)

            Text("借款指南")
                .font(.system(size: 18 * scale, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .position(x: 61 * scale, y: 28 * scale)

            guideLink(asset: "figma-home-guide-icon-1", title: "申请条件", route: .applicationConditions, scale: scale)
                .frame(width: 157 * scale, height: 51 * scale)
                .position(x: 94.5 * scale, y: 77.5 * scale)
            guideLink(asset: "figma-home-guide-icon-2", title: "借款流程", route: .loanProcessGuide, scale: scale)
                .frame(width: 157 * scale, height: 51 * scale)
                .position(x: 263.5 * scale, y: 77.5 * scale)
            guideLink(asset: "figma-home-guide-icon-3", title: "额度说明", route: .quotaGuide, scale: scale)
                .frame(width: 157 * scale, height: 51 * scale)
                .position(x: 94.5 * scale, y: 139.5 * scale)
            guideLink(asset: "figma-home-guide-icon-4", title: "还款说明", route: .repaymentGuide, scale: scale)
                .frame(width: 157 * scale, height: 51 * scale)
                .position(x: 263.5 * scale, y: 139.5 * scale)
        }
    }

    private func guideLink(asset: String, title: String, route: AppRoute, scale: CGFloat) -> some View {
        NavigationLink(value: route) {
            ZStack {
                RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                    .fill(Color(hex: 0xF5F7FA))

                HStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 14 * scale, weight: .medium))
                        .foregroundStyle(JYColor.ink)
                    Spacer(minLength: 2 * scale)
                    Image(asset)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 30 * scale, height: 30 * scale)
                    Spacer().frame(width: 14 * scale)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8 * scale, weight: .semibold))
                        .foregroundStyle(JYColor.secondaryText)
                }
                .padding(.leading, 20 * scale)
                .padding(.trailing, 19 * scale)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(title)
    }
}
