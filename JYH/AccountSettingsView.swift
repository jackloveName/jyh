import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var activeConfirmation: AccountConfirmation?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                accountCard
                accountOptionsCard
                legalCard
                dataCard
                actionsCard
                Text("注销账号前，请确认已结清全部借款并处理完未完成事项。注销后，相关账户信息将按隐私政策及适用法律法规处理。")
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.tertiaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
        .background(JYColor.canvas.ignoresSafeArea())
        .navigationTitle("账户与安全")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if let confirmation = activeConfirmation {
                ConfirmationModal(
                    title: confirmation.title,
                    message: confirmation.message,
                    confirmTitle: confirmation.confirmTitle,
                    isDestructive: confirmation == .deleteAccount,
                    onCancel: {
                        activeConfirmation = nil
                    },
                    onConfirm: {
                        activeConfirmation = nil
                        switch confirmation {
                        case .logout:
                            store.logout()
                        case .deleteAccount:
                            Task {
                                _ = await store.destroyAccount()
                            }
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeConfirmation)
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--show-logout-dialog") {
                activeConfirmation = .logout
            } else if ProcessInfo.processInfo.arguments.contains("--show-delete-dialog") {
                activeConfirmation = .deleteAccount
            }
#endif
        }
    }

    private var accountCard: some View {
        HStack(spacing: 14) {
            UserAvatarView(
                path: store.user.avatar,
                size: 44,
                cacheKey: String(store.avatarRevision)
            )
            VStack(alignment: .leading, spacing: 5) {
                Text(store.user.nickName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(store.user.maskedMobile)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var accountOptionsCard: some View {
        VStack(spacing: 0) {
            NavigationLink(value: AppRoute.profileEdit) {
                settingsRow(title: "更换头像", showsDisclosure: true)
            }
            .buttonStyle(PressScaleStyle())

            Divider().overlay(JYColor.divider).padding(.leading, 18)

            NavigationLink(value: AppRoute.changePassword) {
                settingsRow(title: "修改密码", showsDisclosure: true)
            }
            .buttonStyle(PressScaleStyle())
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var legalCard: some View {
        VStack(spacing: 0) {
            NavigationLink(value: AppRoute.userAgreement) {
                settingsRow(title: "用户服务协议", showsDisclosure: true)
            }
            .buttonStyle(PressScaleStyle())
            Divider().overlay(JYColor.divider).padding(.leading, 18)
            NavigationLink(value: AppRoute.privacyPolicy) {
                settingsRow(title: "隐私政策", showsDisclosure: true)
            }
            .buttonStyle(PressScaleStyle())
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个人信息使用说明")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(JYColor.ink)
            Text("手机号用于登录与账户识别；姓名、身份证号码及申请资料用于实名认证、风险审核和合作机构审批。具体信息处理规则请查看《隐私政策》。")
                .font(.system(size: 13))
                .foregroundStyle(JYColor.secondaryText)
                .lineSpacing(5)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            Button {
                activeConfirmation = .logout
            } label: {
                Text("退出登录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JYColor.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(PressScaleStyle())

            Divider().overlay(JYColor.divider)

            Button {
                activeConfirmation = .deleteAccount
            } label: {
                Text("注销账号")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JYColor.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(PressScaleStyle())
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingsRow(title: String, showsDisclosure: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(JYColor.ink)
            Spacer()
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JYColor.tertiaryText)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
    }
}

private enum AccountConfirmation: Equatable {
    case logout
    case deleteAccount

    var title: String {
        switch self {
        case .logout:
            return "确认退出登录？"
        case .deleteAccount:
            return "确认注销账号？"
        }
    }

    var message: String {
        switch self {
        case .logout:
            return "退出后如需继续使用借款服务，需要重新验证账号。"
        case .deleteAccount:
            return "请确认已结清全部借款并处理完未完成事项。账号注销后无法恢复，相关账户信息将按隐私政策及适用法律法规处理。"
        }
    }

    var confirmTitle: String {
        switch self {
        case .logout:
            return "退出登录"
        case .deleteAccount:
            return "注销账号"
        }
    }
}
