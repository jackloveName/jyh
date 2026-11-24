import PhotosUI
import SwiftUI
import UIKit

struct FeedbackView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSegment: Segment = .submit
    @State private var selectedCategory: FeedbackCategory = .application
    @State private var content = ""
    @State private var allowContact = true
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var records: [FeedbackRecord] = []
    @State private var isLoadingHistory = false
    @State private var isSubmitting = false
    @State private var submitProgress = ""
    @State private var errorMessage: String?
    @State private var successRecord: FeedbackRecord?
    @State private var refreshID = UUID()
    @FocusState private var contentFocused: Bool

    private let maximumContentLength = 500

    var body: some View {
        VStack(spacing: 0) {
            header

            if store.isLoggedIn {
                ScrollView {
                    VStack(spacing: 16) {
                        segmentPicker
                        if selectedSegment == .submit {
                            submissionForm
                        } else {
                            historySection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
            } else {
                loginRequired
            }
        }
        .background(JYColor.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task(id: refreshID) {
            guard store.isLoggedIn else { return }
            await loadHistory()
        }
        .onChange(of: photoItems) { _, items in
            Task {
                await loadSelectedPhotos(items)
            }
        }
        .alert("反馈已提交", isPresented: successAlertBinding) {
            Button("查看记录") {
                selectedSegment = .history
            }
        } message: {
            Text("反馈编号：\(successRecord?.feedbackId ?? "")\n我们会根据反馈内容尽快处理。")
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
            .accessibilityLabel("返回")

            Text("意见反馈")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Color.white)
    }

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            ForEach(Segment.allCases) { segment in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            selectedSegment == segment ? Color.white : JYColor.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            selectedSegment == segment ? JYColor.action : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var submissionForm: some View {
        VStack(spacing: 14) {
            feedbackIntro
            categoryCard
            contentCard
            attachmentCard
            contactCard

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            Button {
                Task {
                    await submit()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSubmitting ? (submitProgress.isEmpty ? "提交中" : submitProgress) : "提交反馈")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    canSubmit ? JYColor.action : Color(hex: 0xAAB7C8),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
            }
            .buttonStyle(PressScaleStyle())
            .disabled(!canSubmit || isSubmitting)

            Text("请勿提交银行卡密码、支付密码、短信验证码或其他与问题无关的敏感信息。")
                .font(.system(size: 11))
                .foregroundStyle(JYColor.tertiaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 12)
        }
    }

    private var feedbackIntro: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [JYColor.action, Color(hex: 0x54A2F7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("告诉我们哪里可以做得更好")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text("请描述发生页面、操作步骤和预期结果，便于快速定位。")
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            formTitle("问题类型", subtitle: "请选择最接近的一项")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 96), spacing: 9)],
                alignment: .leading,
                spacing: 9
            ) {
                ForEach(FeedbackCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(category.title)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            selectedCategory == category ? Color.white : JYColor.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            selectedCategory == category ? JYColor.action : Color(hex: 0xF4F7FB),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                formTitle("问题描述", subtitle: "至少10个字")
                Spacer()
                Text("\(content.count)/\(maximumContentLength)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        content.count > maximumContentLength ? JYColor.danger : JYColor.tertiaryText
                    )
            }

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("请描述您遇到的问题、产品建议或希望改进的内容。")
                        .font(.system(size: 13))
                        .foregroundStyle(JYColor.tertiaryText)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $content)
                    .focused($contentFocused)
                    .font(.system(size: 14))
                    .foregroundStyle(JYColor.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 126)
                    .onChange(of: content) { _, value in
                        if value.count > maximumContentLength {
                            content = String(value.prefix(maximumContentLength))
                        }
                    }
            }
            .padding(10)
            .background(Color(hex: 0xF6F8FB), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var attachmentCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            formTitle("补充截图", subtitle: "选填，最多3张")

            HStack(spacing: 10) {
                ForEach(Array(imageData.enumerated()), id: \.offset) { index, data in
                    ZStack(alignment: .topTrailing) {
                        if let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 76, height: 76)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        Button {
                            imageData.remove(at: index)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Color.black.opacity(0.62), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .offset(x: 5, y: -5)
                    }
                }

                if imageData.count < 3 {
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 3 - imageData.count,
                        matching: .images
                    ) {
                        VStack(spacing: 5) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("添加")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(JYColor.action)
                        .frame(width: 76, height: 76)
                        .background(
                            Color(hex: 0xF4F7FB),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var contactCard: some View {
        VStack(spacing: 13) {
            Toggle(isOn: $allowContact) {
                HStack(spacing: 11) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(JYColor.action)
                        .frame(width: 36, height: 36)
                        .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("允许客服联系我")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(JYColor.ink)
                        Text(allowContact ? store.user.maskedMobile : "不会把手机号写入本次反馈")
                            .font(.system(size: 11))
                            .foregroundStyle(JYColor.secondaryText)
                    }
                }
            }
            .tint(JYColor.action)

            Text("选择允许联系后，客服可能通过已有账号信息与您核对问题，不会索要密码或验证码。")
                .font(.system(size: 11))
                .foregroundStyle(JYColor.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(3)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var historySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("反馈记录")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Spacer()
                Button {
                    refreshID = UUID()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("刷新")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JYColor.action)
                }
                .buttonStyle(.plain)
                .disabled(isLoadingHistory)
            }

            if isLoadingHistory {
                ProgressView("正在读取反馈记录")
                    .tint(JYColor.action)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            } else if records.isEmpty {
                ContentUnavailableView {
                    Label("暂无反馈记录", systemImage: "text.bubble")
                } description: {
                    Text("提交反馈后，可以在这里查看处理状态。")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(records) { record in
                    feedbackRecordCard(record)
                }
            }
        }
    }

    private func feedbackRecordCard(_ record: FeedbackRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(record.categoryName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(JYColor.ink)
                    Text(formatDate(record.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(JYColor.tertiaryText)
                }
                Spacer()
                Text(record.statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(statusColor(record.status))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(statusColor(record.status).opacity(0.1), in: Capsule())
            }

            Text(record.content)
                .font(.system(size: 13))
                .foregroundStyle(JYColor.secondaryText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !record.reply.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "headphones")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(JYColor.action)
                    Text(record.reply)
                        .font(.system(size: 12))
                        .foregroundStyle(JYColor.ink)
                        .lineSpacing(3)
                }
                .padding(11)
                .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Text("编号 \(record.feedbackId)")
                    .font(.system(size: 10))
                    .foregroundStyle(JYColor.tertiaryText)
                Spacer()
                if !record.attachmentPaths.isEmpty {
                    Text("\(record.attachmentPaths.count) 张截图")
                        .font(.system(size: 10))
                        .foregroundStyle(JYColor.tertiaryText)
                }
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var loginRequired: some View {
        ContentUnavailableView {
            Label("登录后提交反馈", systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
            Text("登录后可以提交问题，并查看处理状态。")
        } actions: {
            Button("去登录") {
                store.requestLogin()
            }
            .buttonStyle(.borderedProminent)
            .tint(JYColor.action)
        }
    }

    private func formTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(JYColor.ink)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(JYColor.tertiaryText)
        }
    }

    private var canSubmit: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    private var successAlertBinding: Binding<Bool> {
        Binding(
            get: { successRecord != nil },
            set: { if !$0 { successRecord = nil } }
        )
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        var loaded: [Data] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let compressed = ImageCompressor.compress(
                    data,
                    maxDimension: 1200,
                    quality: 0.75
                  ) else {
                continue
            }
            loaded.append(compressed)
        }
        imageData = Array((imageData + loaded).prefix(3))
        photoItems = []
    }

    @MainActor
    private func loadHistory() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            if store.user.id.isEmpty && store.user.mobile.isEmpty {
                await store.loadProfile()
            }
            records = try await store.loadFeedbackRecords()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func submit() async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else {
            errorMessage = "请至少填写10个字，便于我们理解问题"
            return
        }
        guard !isSubmitting else { return }

        contentFocused = false
        isSubmitting = true
        errorMessage = nil
        defer {
            isSubmitting = false
            submitProgress = ""
        }

        do {
            if store.user.id.isEmpty && store.user.mobile.isEmpty {
                await store.loadProfile()
            }
            var paths: [String] = []
            for (index, data) in imageData.enumerated() {
                submitProgress = "上传截图 \(index + 1)/\(imageData.count)"
                let stamp = Int(Date().timeIntervalSince1970 * 1000)
                let path = try await store.uploadFeedbackAttachment(
                    data,
                    fileName: "feedback-\(stamp)-\(index + 1).jpg"
                )
                paths.append(path)
            }

            submitProgress = "保存反馈"
            let record = try await store.submitFeedback(
                categoryId: selectedCategory.rawValue,
                categoryName: selectedCategory.title,
                content: trimmed,
                attachmentPaths: paths,
                allowContact: allowContact
            )
            records.insert(record, at: 0)
            successRecord = record
            content = ""
            imageData = []
            selectedCategory = .application
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "replied", "closed": return JYColor.success
        case "processing": return JYColor.action
        default: return Color(hex: 0xF7903E)
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "时间未知" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

private enum Segment: String, CaseIterable, Identifiable {
    case submit
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .submit: return "提交反馈"
        case .history: return "反馈记录"
        }
    }
}

private enum FeedbackCategory: String, CaseIterable, Identifiable {
    case application
    case identity
    case review
    case bill
    case account
    case service
    case suggestion
    case complaint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .application: return "借款申请"
        case .identity: return "实名认证"
        case .review: return "审核进度"
        case .bill: return "账单还款"
        case .account: return "账号安全"
        case .service: return "客服服务"
        case .suggestion: return "产品建议"
        case .complaint: return "投诉纠纷"
        }
    }

    var icon: String {
        switch self {
        case .application: return "doc.text.fill"
        case .identity: return "person.text.rectangle.fill"
        case .review: return "clock.badge.checkmark.fill"
        case .bill: return "creditcard.fill"
        case .account: return "lock.shield.fill"
        case .service: return "headphones"
        case .suggestion: return "lightbulb.fill"
        case .complaint: return "exclamationmark.bubble.fill"
        }
    }
}
