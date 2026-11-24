import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var countdown = 0
    @State private var countdownTask: Task<Void, Never>?
    @State private var isSending = false
    @State private var errorText: String?

    private var mobile: String {
        store.user.mobile.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var maskedMobile: String {
        guard mobile.count == 11, !mobile.contains("*") else {
            return mobile.isEmpty ? "未绑定手机号" : mobile
        }
        return mobile.prefix(3) + "****" + mobile.suffix(4)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("通过手机号验证后设置新密码。修改成功后需要重新登录。")
                        .font(.system(size: 13))
                        .foregroundStyle(JYColor.secondaryText)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        inputRow(title: "手机号") {
                            Text(maskedMobile)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(mobile.count == 11 ? JYColor.ink : JYColor.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider().overlay(JYColor.divider).padding(.leading, 14)
                        inputRow(title: "验证码") {
                            TextField("6 位验证码", text: $code)
                                .font(.system(size: 15))
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .onChange(of: code) { _, value in
                                    code = String(value.filter(\.isNumber).prefix(6))
                                }
                            Button(countdown > 0 ? "\(countdown)s" : "获取验证码") {
                                Task {
                                    await sendCode()
                                }
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(countdown > 0 ? JYColor.tertiaryText : JYColor.action)
                            .disabled(countdown > 0 || isSending)
                            .buttonStyle(PressScaleStyle())
                        }
                        Divider().overlay(JYColor.divider).padding(.leading, 14)
                        inputRow(title: "新密码") {
                            SecureField("8–20 位新密码", text: $newPassword)
                                .font(.system(size: 15))
                                .textContentType(.newPassword)
                                .onChange(of: newPassword) { _, value in
                                    let cleaned = String(PasswordPolicy.removingWhitespace(from: value).prefix(20))
                                    if cleaned != value {
                                        newPassword = cleaned
                                    }
                                }
                        }
                        Divider().overlay(JYColor.divider).padding(.leading, 14)
                        inputRow(title: "确认密码") {
                            SecureField("再次输入新密码", text: $confirmPassword)
                                .font(.system(size: 15))
                                .textContentType(.newPassword)
                                .onChange(of: confirmPassword) { _, value in
                                    let cleaned = String(PasswordPolicy.removingWhitespace(from: value).prefix(20))
                                    if cleaned != value {
                                        confirmPassword = cleaned
                                    }
                                }
                        }
                    }
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(PasswordPolicy.ruleDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(JYColor.tertiaryText)
                        .lineSpacing(4)
                        .padding(.horizontal, 4)

                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13))
                            .foregroundStyle(JYColor.danger)
                            .padding(.horizontal, 4)
                    }

                    Button {
                        Task {
                            await submit()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if store.isBusy {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("确认修改")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(JYColor.action, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(PressScaleStyle())
                    .disabled(store.isBusy)
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .background(JYColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            countdownTask?.cancel()
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image("figma-back")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 25, height: 21)
            }
            .buttonStyle(PressScaleStyle())

            Spacer()

            Text("修改密码")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.ink)

            Spacer()

            Color.clear
                .frame(width: 25, height: 21)
        }
        .padding(.horizontal, 20)
        .frame(height: 54)
        .background(Color.white)
    }

    private func inputRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(JYColor.secondaryText)
                .frame(width: 66, alignment: .leading)
            content()
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
    }

    @MainActor
    private func sendCode() async {
        guard mobile.count == 11, mobile.allSatisfy(\.isNumber) else {
            errorText = "未获取到有效手机号，请重新登录后再试"
            return
        }
        isSending = true
        errorText = nil
        if await store.sendCode(mobile: mobile) {
            startCountdown()
        } else {
            errorText = store.toastMessage ?? "验证码发送失败"
        }
        isSending = false
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdown = 60
        countdownTask = Task { @MainActor in
            while countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                countdown -= 1
            }
        }
    }

    @MainActor
    private func submit() async {
        guard mobile.count == 11, mobile.allSatisfy(\.isNumber) else {
            errorText = "未获取到有效手机号，请重新登录后再试"
            return
        }
        guard code.count == 6 else {
            errorText = "请输入 6 位验证码"
            return
        }
        guard PasswordPolicy.isValid(newPassword) else {
            errorText = PasswordPolicy.ruleDescription
            return
        }
        guard newPassword == confirmPassword else {
            errorText = "两次输入的密码不一致"
            return
        }

        errorText = nil
        if let message = await store.changePassword(code: code, newPassword: newPassword) {
            errorText = message
        }
    }
}
