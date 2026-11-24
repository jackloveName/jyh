import PhotosUI
import SwiftUI
import UIKit

struct ProfileEditView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var pickedItem: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var preview: UIImage?
    @State private var compressedSize = ""
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        VStack(spacing: 11) {
                            avatarPreview
                            Text("点击更换头像")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(JYColor.action)
                            if !compressedSize.isEmpty {
                                Text("已压缩至 \(compressedSize)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(JYColor.tertiaryText)
                            }
                        }
                    }
                    .buttonStyle(PressScaleStyle())

                    VStack(alignment: .leading, spacing: 10) {
                        Text("头像说明")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(JYColor.ink)
                        Text("请选择清晰、合法的个人图片。上传后会同步用于账户展示。")
                            .font(.system(size: 13))
                            .foregroundStyle(JYColor.secondaryText)
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13))
                            .foregroundStyle(JYColor.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if store.isBusy {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("保存头像")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(JYColor.action, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(PressScaleStyle())
                    .disabled(store.isBusy)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .background(JYColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                await load(item)
            }
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

            Text("更换头像")
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

    private var avatarPreview: some View {
        Group {
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
            } else {
                UserAvatarView(
                    path: store.user.avatar,
                    size: 104,
                    cacheKey: String(store.avatarRevision)
                )
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.white, lineWidth: 3)
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(JYColor.action, in: Circle())
                .overlay {
                    Circle().stroke(Color.white, lineWidth: 2)
                }
                .offset(x: 2, y: 2)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 5)
    }

    @MainActor
    private func load(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let compressed = ImageCompressor.compress(data) else {
                throw APIError.invalidResponse
            }
            avatarData = compressed
            preview = UIImage(data: compressed)
            compressedSize = ImageCompressor.sizeText(compressed)
            errorText = nil
        } catch {
            errorText = "无法读取所选图片，请换一张图片"
        }
    }

    @MainActor
    private func save() async {
        guard let avatarData else {
            errorText = "请先选择新头像"
            return
        }
        errorText = nil
        if let message = await store.updateAvatar(data: avatarData) {
            errorText = message
            return
        }
        dismiss()
    }
}
