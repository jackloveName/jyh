import SwiftUI

struct UserAvatarView: View {
    let path: String
    let size: CGFloat
    var cacheKey = ""

    var body: some View {
        Group {
            if let url = APIClient.shared.resourceURL(path, cacheKey: cacheKey) {
                AsyncImage(url: url, transaction: .init(animation: .easeOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallback
                    case .empty:
                        fallback
                            .overlay {
                                ProgressView()
                                    .controlSize(.small)
                            }
                    @unknown default:
                        fallback
                    }
                }
                .id(url.absoluteString)
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallback: some View {
        Image("figma-profile-avatar")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
    }
}
