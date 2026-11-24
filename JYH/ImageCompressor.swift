import UIKit

enum ImageCompressor {
    static func compress(
        _ data: Data,
        maxDimension: CGFloat = 800,
        quality: CGFloat = 0.8
    ) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let width = image.size.width
        let height = image.size.height
        guard width > 0, height > 0 else { return nil }

        let scale = min(1, maxDimension / max(width, height))
        let targetSize = CGSize(width: width * scale, height: height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    static func sizeText(_ data: Data) -> String {
        let kb = Double(data.count) / 1024
        if kb < 1024 {
            return String(format: "%.0f KB", kb)
        }
        return String(format: "%.1f MB", kb / 1024)
    }
}
