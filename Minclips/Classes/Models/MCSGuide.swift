import Foundation

public enum MCSGuide: Hashable {

    case story(media: String, title: String, detail: String, button: String)

    case cast(title: String, detail: String, button: String)

}

/// 全局「最近所选」：`PHAsset.localIdentifier` 存入 `UserDefaults`；若无 `assetIdentifier`，则用占位 id + Cache 内 JPEG。
public enum MCCRecentPickedPhotoStore {

    private static let udKey = "mcc.recentPickedPhotoLocalIds"

    /// Not a Photos id; denotes `fallbackJPEGRelativePath` written under Caches.
    public static let photoLibraryFallbackPlaceholderId = "__mcc_recent_picked_fallback_jpeg__"

    private static let fallbackJPEGRelativePathKey = "mcc.recentPickedFallbackJPEGRelative"

    private static let maxCount = 30

    private static let fallbackJPEGFileName = "mcc_recent_picked_fallback.jpg"

    public static func record(localIdentifier: String) {
        let trimmed = localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        clearFallbackJPEGStaleState()
        var list = UserDefaults.standard.stringArray(forKey: udKey) ?? []
        list.removeAll { $0 == trimmed || $0 == Self.photoLibraryFallbackPlaceholderId }
        list.insert(trimmed, at: 0)
        if list.count > maxCount {
            list = Array(list.prefix(maxCount))
        }
        UserDefaults.standard.set(list, forKey: udKey)
    }

    /// When `PHPickerResult.assetIdentifier` is nil but an image was chosen, persist JPEG so Recent can resolve a thumbnail (`photoLibraryFallbackPlaceholderId` as first entry).
    public static func recordFallbackJPEGData(_ data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return false }
        let url = base.appendingPathComponent(fallbackJPEGFileName, isDirectory: false)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return false
        }
        let rel = fallbackJPEGRelativePath(fromCachesFileURL: url)
        UserDefaults.standard.set(rel, forKey: fallbackJPEGRelativePathKey)
        var list = UserDefaults.standard.stringArray(forKey: udKey) ?? []
        list.removeAll { $0 == photoLibraryFallbackPlaceholderId }
        list.insert(photoLibraryFallbackPlaceholderId, at: 0)
        if list.count > maxCount {
            list = Array(list.prefix(maxCount))
        }
        UserDefaults.standard.set(list, forKey: udKey)
        return true
    }

    public static var localIdentifiers: [String] {
        UserDefaults.standard.stringArray(forKey: udKey) ?? []
    }

    /// True when the Recent tile should show (valid asset id or on-disk fallback JPEG).
    public static func hasValidRecentPickForTile() -> Bool {
        guard let first = localIdentifiers.first else { return false }
        if first == photoLibraryFallbackPlaceholderId {
            return fallbackJPEGFileURLIfPresent() != nil
        }
        return true
    }

    public static func fallbackJPEGFileURLIfPresent() -> URL? {
        guard let rel = UserDefaults.standard.string(forKey: fallbackJPEGRelativePathKey), !rel.isEmpty else { return nil }
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let url = base.appendingPathComponent(rel)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func clearFallbackJPEGStaleState() {
        if let u = fallbackJPEGFileURLIfPresent() {
            try? FileManager.default.removeItem(at: u)
        }
        UserDefaults.standard.removeObject(forKey: fallbackJPEGRelativePathKey)
    }

    private static func fallbackJPEGRelativePath(fromCachesFileURL url: URL) -> String {
        let name = url.lastPathComponent
        return name.isEmpty ? fallbackJPEGFileName : name
    }
}
