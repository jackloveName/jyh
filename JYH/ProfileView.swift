import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showLogoutConfirmation = false
    @State private var showBill = false

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 390

            ScrollView {
                ZStack(alignment: .topLeading) {
                    JYColor.canvas

                    avatarEntry(scale: scale)
                        .frame(width: 62 * scale, height: 62 * scale)
                        .position(x: 63 * scale, y: 114 * scale)

                    Text(store.isLoggedIn ? store.user.maskedMobile : "138 **** 8888")
                        .font(.system(size: 19 * scale, weight: .bold))
                        .foregroundStyle(JYColor.ink)
                        .position(x: 168 * scale, y: 126 * scale)
                        .onTapGesture {
                            if !store.isLoggedIn {
                                store.requestLogin()
                            }
                        }

                    settingsButton(scale: scale)
                    .position(x: 363.5 * scale, y: 93.5 * scale)

                    quotaCard(scale: scale)
                        .frame(width: 358 * scale, height: 130 * scale)
                        .position(x: 195 * scale, y: 227 * scale)

                    quickActions(scale: scale)
                        .frame(width: 358 * scale, height: 103 * scale)
                        .position(x: 195 * scale, y: 355.5 * scale)

                    serviceList(scale: scale)
                        .frame(width: 358 * scale, height: 270 * scale)
                        .position(x: 195 * scale, y: 556 * scale)

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
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(JYColor.secondaryText)
                        .position(x: 195 * scale, y: 713 * scale)
                        .accessibilityLabel("查看合作机构")
                    }
                }
                .frame(width: proxy.size.width, height: 746 * scale, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .background(JYColor.canvas.ignoresSafeArea())
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden()
        .overlay {
            if showLogoutConfirmation {
                ConfirmationModal(
                    title: "确认退出登录？",
                    message: "退出后如需继续使用借款服务，需要重新验证账号。",
                    confirmTitle: "退出登录",
                    onCancel: {
                        showLogoutConfirmation = false
                    },
                    onConfirm: {
                        showLogoutConfirmation = false
                        store.logout()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showLogoutConfirmation)
        .fullScreenCover(isPresented: $showBill) {
            NavigationStack {
                FinancialWebView(title: "我的账单", url: store.repaymentFlowURL)
                    .environmentObject(store)
            }
        }
        .task(id: store.storedLoanApplication?.reviewDeadlineAt) {
            guard store.isLoggedIn else { return }
            await store.loadStoredLoanApplicationIfNeeded()
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
    }

    @ViewBuilder
    private func settingsButton(scale: CGFloat) -> some View {
        if store.isLoggedIn {
            NavigationLink(value: AppRoute.settings) {
                settingsImage(scale: scale)
            }
            .buttonStyle(PressScaleStyle())
        } else {
            Button {
                store.requestLogin()
            } label: {
                settingsImage(scale: scale)
            }
            .buttonStyle(PressScaleStyle())
        }
    }

    @ViewBuilder
    private func avatarEntry(scale: CGFloat) -> some View {
        if store.isLoggedIn {
            NavigationLink(value: AppRoute.profileEdit) {
                UserAvatarView(
                    path: store.user.avatar,
                    size: 62 * scale,
                    cacheKey: String(store.avatarRevision)
                )
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("更换头像")
        } else {
            Button {
                store.requestLogin()
            } label: {
                UserAvatarView(path: "", size: 62 * scale)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("登录后管理头像")
        }
    }

    private func settingsImage(scale: CGFloat) -> some View {
        Image("figma-profile-settings")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 19.5 * scale, height: 17.5 * scale)
    }

    private func quotaCard(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x086CF5), Color(hex: 0x0875F2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(store.quotaReferenceLabel)
                .font(.system(size: 14 * scale, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .position(x: 81 * scale, y: 34 * scale)

            Text(store.maskedQuotaText)
                .font(
                    .system(
                        size: store.hasRejectedBorrowApplication ? 31 * scale : 43 * scale,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .frame(width: 174 * scale, alignment: .leading)
                .position(x: 97 * scale, y: 68 * scale)

            NavigationLink(value: profileQuotaDestination) {
                Text(store.hasRejectedBorrowApplication ? "查看详情" : "查看额度")
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(JYColor.action)
                    .frame(width: 80 * scale, height: 30 * scale)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(PressScaleStyle())
            .position(x: 296 * scale, y: 77 * scale)

            Text(store.quotaDescriptionText)
                .font(.system(size: 12 * scale))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 260 * scale, alignment: .leading)
                .position(x: 147 * scale, y: 109 * scale)
        }
    }

    private var profileQuotaDestination: AppRoute {
        if store.hasRejectedBorrowApplication { return .h5LoanResult }
        return store.isLoggedIn ? .loanFlow : .safety
    }

    private func quickActions(scale: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(Color.white)

            HStack(spacing: 0) {
                billQuickAction(scale: scale)
                quickAction(asset: "figma-profile-action-2", title: "额度评估", route: .quotaGuide, scale: scale)
                quickAction(asset: "figma-profile-action-3", title: "个人资料", route: store.isLoggedIn ? .profileEdit : .safety, scale: scale)
                quickAction(asset: "figma-profile-action-4", title: "还款指南", route: .repaymentGuide, scale: scale)
            }
            .padding(.horizontal, 14 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func billQuickAction(scale: CGFloat) -> some View {
        if store.isLoggedIn {
            Button {
                let url = store.repaymentFlowURL
                JYHDiagnostics.log(
                    "账单",
                    "点击我的账单 isLoggedIn=\(store.isLoggedIn) token=\(JYHDiagnostics.tokenStatus(store.token)) url=\(JYHDiagnostics.redactedURL(url))"
                )
                showBill = true
            } label: {
                quickActionLabel(asset: "figma-profile-action-1", title: "我的账单", scale: scale)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("我的账单")
        } else {
            Button {
                store.requestLogin()
            } label: {
                quickActionLabel(asset: "figma-profile-action-1", title: "我的账单", scale: scale)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("登录后查看我的账单")
        }
    }

    private func quickAction(asset: String, title: String, route: AppRoute, scale: CGFloat) -> some View {
        quickAction(title: title, route: route, scale: scale) {
            Image(asset)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 44 * scale, height: 44 * scale)
        }
    }

    private func quickAction<Icon: View>(
        title: String,
        route: AppRoute,
        scale: CGFloat,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        NavigationLink(value: route) {
            quickActionContent(title: title, scale: scale, icon: icon)
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(title)
    }

    private func quickActionLabel(asset: String, title: String, scale: CGFloat) -> some View {
        quickActionContent(title: title, scale: scale) {
            Image(asset)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 44 * scale, height: 44 * scale)
        }
    }

    private func quickActionContent<Icon: View>(
        title: String,
        scale: CGFloat,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        VStack(spacing: 6 * scale) {
            icon()
                .frame(width: 44 * scale, height: 44 * scale)
            Text(title)
                .font(.system(size: 12 * scale, weight: .medium))
                .foregroundStyle(JYColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(height: 17 * scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private func serviceList(scale: CGFloat) -> some View {
        VStack(spacing: 10 * scale) {
            serviceRow(
                title: "意见反馈",
                icon: "bubble.left.and.bubble.right.fill",
                route: .feedback,
                scale: scale
            )
            serviceRow(
                title: "在线客服",
                icon: "headphones",
                route: .support,
                scale: scale
            )
            serviceRow(
                title: "帮助中心",
                icon: "questionmark.circle.fill",
                route: .helpCenter,
                scale: scale
            )
            serviceRow(
                title: "关于我们",
                icon: "info.circle.fill",
                route: .about,
                scale: scale
            )
        }
    }

    private func serviceRow(
        title: String,
        icon: String,
        route: AppRoute,
        scale: CGFloat
    ) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 12 * scale) {
                Image(systemName: icon)
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(JYColor.action)
                    .frame(width: 34 * scale, height: 34 * scale)
                    .background(
                        JYColor.primarySoft,
                        in: RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                    )
                Text(title)
                    .font(.system(size: 15 * scale, weight: .medium))
                    .foregroundStyle(JYColor.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11 * scale, weight: .semibold))
                    .foregroundStyle(JYColor.secondaryText.opacity(0.7))
            }
            .padding(.horizontal, 14 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .background(
                Color.white,
                in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
            )
        }
        .buttonStyle(PressScaleStyle())
        .frame(maxWidth: .infinity)
        .frame(height: 60 * scale)
        .contentShape(Rectangle())
    }
}
