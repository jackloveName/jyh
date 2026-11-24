import SwiftUI

struct RootView: View {
    @ObservedObject var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Group {
                if store.hasEnteredApp {
                    MainShellView()
                } else {
                    LoginView(isModal: false)
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: store.hasEnteredApp)
        .sheet(isPresented: $store.showLogin) {
            LoginView(isModal: true)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .overlay(alignment: .top) {
            if let message = store.toastMessage {
                ToastBanner(message: message)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .overlay {
            if store.isBusy {
                LoadingOverlay()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: store.toastMessage)
        .jyDismissKeyboardOnBackgroundTap()
        .task {
            await store.loadAppConfiguration()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, store.isLoggedIn else { return }
            Task {
                await store.refreshAll()
            }
        }
    }
}

struct MainShellView: View {
    @EnvironmentObject private var store: AppStore
    @State private var path: NavigationPath

    init() {
        var initialPath = NavigationPath()
#if DEBUG
        if let flagIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--route"),
           ProcessInfo.processInfo.arguments.indices.contains(flagIndex + 1) {
            switch ProcessInfo.processInfo.arguments[flagIndex + 1] {
            case "loan":
                initialPath.append(AppRoute.loanFlow)
            case "bill":
                initialPath.append(AppRoute.h5Bill)
            case "settings":
                initialPath.append(AppRoute.settings)
            case "conditions":
                initialPath.append(AppRoute.applicationConditions)
            case "process":
                initialPath.append(AppRoute.loanProcessGuide)
            case "quota":
                initialPath.append(AppRoute.quotaGuide)
            case "repayment-guide":
                initialPath.append(AppRoute.repaymentGuide)
            case "support":
                initialPath.append(AppRoute.support)
            default:
                break
            }
        }
#endif
        _path = State(initialValue: initialPath)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                switch store.selectedTab {
                case .home:
                    HomeView()
                case .profile:
                    ProfileView()
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if path.isEmpty {
                    JYTabBar()
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .loanFlow:
                    FinancialWebView(title: "借款申请", url: store.loanFlowURL)
                case .repaymentHistory:
                    FinancialWebView(title: "还款账单", url: store.repaymentFlowURL)
                case .support:
                    FinancialWebView(
                        title: "在线客服",
                        url: store.customerServiceURL,
                        showsNativeBackButton: true
                    )
                case .helpCenter:
                    HelpCenterView()
                case .lenders:
                    LenderDirectoryView()
                case .about:
                    AboutView()
                case .safety:
                    SafetyView()
                case .settings:
                    AccountSettingsView()
                case .feedback:
                    FeedbackView()
                case .userAgreement:
                    LegalDocumentView(type: .userAgreement)
                case .privacyPolicy:
                    LegalDocumentView(type: .privacyPolicy)
                case .changePassword:
                    ChangePasswordView()
                case .profileEdit:
                    ProfileEditView()
                case .h5Identity:
                    FinancialWebView(title: "身份认证", url: store.identityCardURL)
                case .h5Face:
                    FinancialWebView(title: "人脸核验", url: store.faceRecognitionURL)
                case .h5Profile:
                    FinancialWebView(title: "完善资料", url: store.profileInformationURL)
                case .h5LoanResult:
                    FinancialWebView(title: "借款申请详情", url: store.loanReviewDetailURL)
                case .h5Bill:
                    FinancialWebView(title: "我的账单", url: store.repaymentFlowURL)
                case .applicationConditions:
                    ApplicationConditionsGuideView()
                case .loanProcessGuide:
                    LoanProcessGuideView()
                case .quotaGuide:
                    QuotaGuideView()
                case .repaymentGuide:
                    RepaymentGuideView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            if store.isLoggedIn {
                await store.refreshAll()
            }
        }
        .onChange(of: path.count) { _, depth in
            guard depth == 0, store.isLoggedIn else { return }
            Task {
                await store.loadStoredLoanApplicationIfNeeded()
            }
        }
    }
}

private struct JYTabBar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack {
            ForEach(MainTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        tabIcon(for: tab)
                            .frame(width: 32, height: 31)
                        Text(tab.title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(store.selectedTab == tab ? JYColor.action : JYColor.secondaryText)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleStyle())
            }
        }
        .padding(.horizontal, 34)
        .padding(.top, 14)
        .frame(height: 64, alignment: .top)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.06), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func tabIcon(for tab: MainTab) -> some View {
        Image(assetName(for: tab))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .symbolEffect(.bounce, value: store.selectedTab == tab)
    }

    private func assetName(for tab: MainTab) -> String {
        let selected = store.selectedTab == tab
        switch tab {
        case .home:
            return selected ? "figma-tab-borrow-selected" : "figma-tab-borrow"
        case .profile:
            return selected ? "figma-tab-profile-selected" : "figma-tab-profile"
        }
    }
}

private struct SafetyView: View {
    @EnvironmentObject private var store: AppStore

    private var items: [(String, String, String)] {
        var values = [
            ("lock.shield.fill", "信息保护", "账户与身份信息仅按隐私政策和授权范围处理。"),
            ("hand.raised.fill", "授权管理", "除法律法规许可或取得授权外，不向无关第三方提供个人信息。"),
            ("exclamationmark.triangle.fill", "理性借贷", "请结合收入与负债情况审慎借贷，逾期可能影响信用记录。")
        ]
        if let institution = store.currentLenderInstitution {
            values.insert(
                ("checkmark.seal.fill", "合作机构", "借款服务由\(institution.name)提供。"),
                at: 1
            )
        }
        return values
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(items, id: \.0) { item in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.0)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(JYColor.primary)
                            .frame(width: 42, height: 42)
                            .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 13))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.1)
                                .font(.system(size: 16, weight: .semibold))
                            Text(item.2)
                                .font(.system(size: 13))
                                .foregroundStyle(JYColor.secondaryText)
                                .lineSpacing(4)
                        }
                    }
                    .jyCard(padding: 16)
                }
            }
            .padding(18)
        }
        .jyScreenBackground()
        .navigationTitle("安全保障")
        .navigationBarTitleDisplayMode(.inline)
    }
}
