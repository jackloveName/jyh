import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 52
    var light = false

    var body: some View {
        Image("jyh-logo")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .shadow(color: Color.black.opacity(light ? 0.08 : 0.12), radius: 12, y: 6)
    }
}

struct ProviderShieldIcon: View {
    var scale: CGFloat = 1

    var body: some View {
        Image("figma-login-shield")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 10.5 * scale, height: 13 * scale)
            .accessibilityHidden(true)
    }
}

struct ConfirmationModal: View {
    let title: String
    let message: String
    let confirmTitle: String
    var isDestructive = false
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(JYColor.ink)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(JYColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 12)

                HStack(spacing: 0) {
                    actionButton(
                        title: "取消",
                        foreground: JYColor.action,
                        background: Color.white,
                        border: JYColor.action,
                        action: onCancel
                    )

                    Spacer().frame(width: 20)

                    actionButton(
                        title: confirmTitle,
                        foreground: Color.white,
                        background: isDestructive ? JYColor.danger : JYColor.action,
                        border: isDestructive ? JYColor.danger : JYColor.action,
                        action: onConfirm
                    )
                }
                .padding(.top, 28)
            }
            .padding(20)
            .frame(maxWidth: 326)
            .background(
                Color.white,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 24, y: 12)
            .padding(.horizontal, 32)
        }
        .accessibilityAddTraits(.isModal)
        .ignoresSafeArea()
    }

    private func actionButton(
        title: String,
        foreground: Color,
        background: Color,
        border: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    background,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(border, lineWidth: 1)
                }
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(JYColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(JYColor.tertiaryText)
                }
            }
            Spacer()
            if let actionTitle {
                Button(actionTitle) {
                    action?()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(JYColor.primary)
                .buttonStyle(PressScaleStyle())
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = JYColor.ink
    var icon: String?

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(JYColor.primary)
                    .frame(width: 30, height: 30)
                    .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(JYColor.secondaryText)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct MenuRow: View {
    let title: String
    var subtitle: String?
    let icon: String
    var tint: Color = JYColor.primary

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(JYColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(JYColor.tertiaryText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JYColor.tertiaryText.opacity(0.7))
        }
    }
}

struct StatusBadge: View {
    let text: String
    var color: Color = JYColor.success

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.1), in: Capsule())
    }
}

struct DashedPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(JYColor.primarySoft.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(JYColor.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            }
    }
}

struct ToastBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x20232A, alpha: 0.94), in: Capsule())
        .shadow(color: Color.black.opacity(0.14), radius: 16, y: 8)
        .padding(.horizontal, 24)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.08).ignoresSafeArea()
            ProgressView()
                .tint(JYColor.primary)
                .padding(22)
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

extension Double {
    var amountString: String {
        formatted(.number.grouping(.automatic).precision(.fractionLength(0)))
    }

    var moneyString: String {
        formatted(.number.grouping(.automatic).precision(.fractionLength(2)))
    }
}
