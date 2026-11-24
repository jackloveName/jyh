import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let isModal: Bool

    @State private var principal = ""
    @State private var verificationCode = ""
    @State private var password = ""
    @State private var loginMethod: LoginMethod = .code
    @State private var isPasswordVisible = false
    @State private var agreed = false
    @State private var showAgreementError = false
    @State private var codeCountdown = 0
    @State private var countdownTask: Task<Void, Never>?
    @State private var legalDocumentType: LegalDocumentType?
    @State private var showLenderDirectory = false

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 390
            let canvasHeight = max(proxy.size.height, 844 * scale)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: 0xE7F1FC), location: 0),
                            .init(color: Color(hex: 0xE9F2FC), location: 0.36),
                            .init(color: Color(hex: 0xF3F7FC), location: 0.76),
                            .init(color: .white, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: 360 * scale)

                    Image("jyh-logo")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 42 * scale, height: 42 * scale)
                        .position(x: 52 * scale, y: 124 * scale)

                    Text(AppConfig.appName)
                        .font(.system(size: 28 * scale, weight: .bold))
                        .foregroundStyle(JYColor.ink)
                        .position(x: 125 * scale, y: 120 * scale)

                    Image("login-coin")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 153 * scale, height: 148 * scale)
                        .position(x: 282.5 * scale, y: 239 * scale)

                    Text("欢迎登录")
                        .font(.system(size: 30 * scale, weight: .bold))
                        .foregroundStyle(JYColor.ink)
                        .position(x: 87.7 * scale, y: 251 * scale)

                    Text(loginMethod == .code
                        ? "未注册手机号将创建账户"
                        : "请使用已注册账号和密码登录")
                        .font(.system(size: 14 * scale))
                        .foregroundStyle(JYColor.secondaryText)
                        .frame(width: 300 * scale, alignment: .leading)
                        .position(x: 182 * scale, y: 281 * scale)

                    loginMethodPicker(scale: scale)
                        .frame(width: 250 * scale, height: 36 * scale)
                        .position(x: 195 * scale, y: 310 * scale)

                    phoneField(scale: scale)
                        .frame(width: 326 * scale, height: 58 * scale)
                        .position(x: 195 * scale, y: 367 * scale)

                    credentialField(scale: scale)
                        .frame(width: 326 * scale, height: 58 * scale)
                        .position(x: 195 * scale, y: 441 * scale)

                    agreement(scale: scale)
                        .frame(width: 326 * scale, height: 28 * scale)
                        .position(x: 195 * scale, y: 504 * scale)

                    loginButton(scale: scale)
                        .frame(width: 326 * scale, height: 52 * scale)
                        .position(x: 195 * scale, y: 573 * scale)

                    footer(scale: scale)
                        .frame(maxWidth: .infinity)
                        .position(x: proxy.size.width / 2, y: 779 * scale)
                }
                .frame(width: proxy.size.width, height: canvasHeight, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .background(Color.white.ignoresSafeArea())
        }
        .ignoresSafeArea(edges: .top)
        .jyDismissKeyboardOnBackgroundTap()
        .jyKeyboardDoneButton()
        .overlay(alignment: .topTrailing) {
            if isModal {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(JYColor.ink)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.9), in: Circle())
                }
                .padding(.top, 58)
                .padding(.trailing, 20)
            }
        }
        .onDisappear {
            countdownTask?.cancel()
        }
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--password-login") {
                loginMethod = .password
            }
#endif
        }
        .sheet(item: $legalDocumentType) { type in
            NavigationStack {
                LegalDocumentView(type: type)
            }
        }
        .sheet(isPresented: $showLenderDirectory) {
            NavigationStack {
                LenderDirectoryView()
                    .environmentObject(store)
            }
        }
    }

    private func loginMethodPicker(scale: CGFloat) -> some View {
        HStack(spacing: 4 * scale) {
            ForEach(LoginMethod.allCases, id: \.rawValue) { method in
                let selected = loginMethod == method

                Button {
                    selectLoginMethod(method)
                } label: {
                    Text(method.rawValue)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(selected ? Color.white : JYColor.secondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            selected ? JYColor.primary : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3 * scale)
        .background(Color.white.opacity(0.88), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        }
    }

    private func phoneField(scale: CGFloat) -> some View {
        HStack(spacing: 15 * scale) {
            Image("figma-login-phone-icon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 17 * scale, height: 24 * scale)

            TextField(
                loginMethod == .code ? "请输入手机号" : "请输入手机号或账号",
                text: $principal
            )
                .font(.system(size: 16 * scale, weight: .medium))
                .foregroundStyle(JYColor.ink)
                .keyboardType(loginMethod == .code ? .phonePad : .default)
                .textContentType(loginMethod == .code ? .telephoneNumber : .username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: principal) { _, value in
                    guard loginMethod == .code else { return }
                    let digits = String(value.filter(\.isNumber).prefix(11))
                    if digits != value {
                        principal = digits
                    }
                }
        }
        .padding(.leading, 30 * scale)
        .padding(.trailing, 12 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .stroke(Color(hex: 0xEEF1F5), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func credentialField(scale: CGFloat) -> some View {
        if loginMethod == .code {
            codeField(scale: scale)
        } else {
            passwordField(scale: scale)
        }
    }

    private func codeField(scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {
            Image("figma-login-code-icon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 22 * scale, height: 25 * scale)

            TextField("请输入6位验证码", text: $verificationCode)
                .font(.system(size: 16 * scale, weight: .medium))
                .foregroundStyle(JYColor.ink)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: verificationCode) { _, value in
                    verificationCode = String(value.filter(\.isNumber).prefix(6))
                }

            Rectangle()
                .fill(Color(hex: 0xD8DEE8))
                .frame(width: 1, height: 22 * scale)

            Button {
                Task {
                    if await store.sendCode(mobile: principal) {
                        startCountdown()
                    }
                }
            } label: {
                Text(codeCountdown > 0 ? "\(codeCountdown)s" : "获取验证码")
                    .font(.system(size: 13 * scale, weight: .medium))
                    .foregroundStyle(codeCountdown > 0 ? JYColor.tertiaryText : JYColor.primary)
                    .frame(width: 82 * scale)
            }
            .disabled(codeCountdown > 0 || store.isBusy)
            .buttonStyle(PressScaleStyle())
        }
        .padding(.leading, 28 * scale)
        .padding(.trailing, 12 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .stroke(Color(hex: 0xEEF1F5), lineWidth: 1)
        }
    }

    private func passwordField(scale: CGFloat) -> some View {
        HStack(spacing: 13 * scale) {
            Image(systemName: "lock")
                .font(.system(size: 19 * scale, weight: .medium))
                .foregroundStyle(JYColor.secondaryText)
                .frame(width: 22 * scale, height: 25 * scale)

            Group {
                if isPasswordVisible {
                    TextField("请输入登录密码", text: $password)
                } else {
                    SecureField("请输入登录密码", text: $password)
                }
            }
            .font(.system(size: 16 * scale, weight: .medium))
            .foregroundStyle(JYColor.ink)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: password) { _, value in
                if value.count > 32 {
                    password = String(value.prefix(32))
                }
            }

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .font(.system(size: 18 * scale, weight: .regular))
                    .foregroundStyle(JYColor.secondaryText)
                    .frame(width: 32 * scale, height: 32 * scale)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(isPasswordVisible ? "隐藏密码" : "显示密码")
        }
        .padding(.leading, 28 * scale)
        .padding(.trailing, 12 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .stroke(Color(hex: 0xEEF1F5), lineWidth: 1)
        }
    }

    private func agreement(scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            Button {
                agreed.toggle()
                showAgreementError = false
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                        .fill(agreed ? JYColor.primary : Color.white)

                    RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                        .stroke(
                            showAgreementError ? JYColor.danger : (agreed ? JYColor.primary : Color(hex: 0xA7AFBC)),
                            lineWidth: showAgreementError ? 1.5 : 1
                        )

                    if agreed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12 * scale, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 20 * scale, height: 20 * scale)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("同意用户协议和隐私政策")
            .accessibilityValue(agreed ? "已勾选" : "未勾选")

            Button {
                agreed.toggle()
                showAgreementError = false
            } label: {
                Text("我已阅读并同意")
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(JYColor.secondaryText)
            }
            .buttonStyle(PressScaleStyle())
            .padding(.leading, 16 * scale)

            Button {
                legalDocumentType = .userAgreement
            } label: {
                Text("《用户协议》")
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(JYColor.primary)
            }
            .buttonStyle(PressScaleStyle())

            Button {
                legalDocumentType = .privacyPolicy
            } label: {
                Text("《隐私政策》")
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(JYColor.primary)
            }
            .buttonStyle(PressScaleStyle())
        }
        .lineLimit(1)
        .minimumScaleFactor(0.82)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12 * scale)
    }

    private func loginButton(scale: CGFloat) -> some View {
        Button {
            submitLogin()
        } label: {
            HStack(spacing: 8 * scale) {
                if store.isBusy {
                    ProgressView()
                        .tint(.white)
                }
                Text("登录")
                    .font(.system(size: 16 * scale, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                    .fill(JYColor.primary)
            )
        }
        .disabled(store.isBusy)
        .buttonStyle(PressScaleStyle())
    }

    private func selectLoginMethod(_ method: LoginMethod) {
        withAnimation(.easeInOut(duration: 0.2)) {
            loginMethod = method
            isPasswordVisible = false
            if method == .code {
                principal = String(principal.filter(\.isNumber).prefix(11))
            }
        }
    }

    private func submitLogin() {
        guard agreed else {
            withAnimation(.easeInOut(duration: 0.16)) {
                showAgreementError = true
            }
            store.showToast("请先阅读并勾选《用户协议》和《隐私政策》")
            return
        }
        let credential = loginMethod == .code ? verificationCode : password
        Task {
            _ = await store.login(
                method: loginMethod,
                principal: principal,
                credential: credential
            )
        }
    }

    @ViewBuilder
    private func footer(scale: CGFloat) -> some View {
        if let disclosure = store.providerDisclosure {
            Button {
                showLenderDirectory = true
            } label: {
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
            .accessibilityLabel("查看合作机构")
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        codeCountdown = 60
        countdownTask = Task {
            while codeCountdown > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                codeCountdown -= 1
            }
        }
    }
}

