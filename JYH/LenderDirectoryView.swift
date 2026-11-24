import SwiftUI

struct LenderDirectoryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero

                    if store.lenderInstitutions.isEmpty {
                        ContentUnavailableView {
                            Label("暂无合作机构", systemImage: "building.2")
                        } description: {
                            Text("当前没有可展示的合作机构信息。")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        VStack(alignment: .leading, spacing: 11) {
                            HStack {
                                Text("合作机构列表")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(JYColor.ink)
                                Spacer()
                                Text("\(store.lenderInstitutions.count) 家")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(JYColor.tertiaryText)
                            }

                            ForEach(store.lenderInstitutions) { institution in
                                LenderInstitutionCard(institution: institution)
                            }
                        }

                        explanationCard(
                            icon: "building.columns.fill",
                            title: "助贷平台说明",
                            message: "\(AppConfig.appName)提供借款信息展示和申请流程服务。合作机构根据用户授权及自身规则独立完成审核、授信和合同确认。"
                        )

                        explanationCard(
                            icon: "doc.text.fill",
                            title: "以申请页面和合同为准",
                            message: "实际出借机构、额度、期限、综合融资成本及还款安排，以提交申请时页面展示的信息和最终签署的借款合同为准。"
                        )

                        NavigationLink(value: AppRoute.support) {
                            HStack(spacing: 10) {
                                Image(systemName: "headphones")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("对合作机构有疑问？联系在线客服")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(JYColor.action)
                            .padding(.horizontal, 15)
                            .frame(height: 52)
                            .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PressScaleStyle())
                    }
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

            Text("合作机构")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JYColor.ink)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Color.white)
    }

    private var hero: some View {
        HStack(spacing: 15) {
            Image(systemName: "building.2.fill")
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
                Text("借款服务合作机构")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JYColor.ink)
                Text("机构信息会根据实际合作情况持续更新。")
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

    private func explanationCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(JYColor.action)
                .frame(width: 36, height: 36)
                .background(JYColor.primarySoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(JYColor.secondaryText)
                    .lineSpacing(4)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct LenderInstitutionCard: View {
    let institution: LenderInstitution

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Text(String(institution.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(
                            colors: [JYColor.action, Color(hex: 0x59A5F7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )

                Text(institution.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(JYColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
