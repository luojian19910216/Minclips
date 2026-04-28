import Foundation

public enum MCSGuide: Hashable {

    case story(media: String, title: String, detail: String, button: String)

    case cast(title: String, detail: String, button: String)

}

/// 全局「最近所选」相册 `localIdentifier`（`UserDefaults`，跨进程/冷启动）；与引导/详情等共享。服务端 Recent 列表后续再接。
public enum MCCRecentPickedPhotoStore {

    private static let udKey = "mcc.recentPickedPhotoLocalIds"

    private static let maxCount = 30

    public static func record(localIdentifier: String) {
        let trimmed = localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var list = UserDefaults.standard.stringArray(forKey: udKey) ?? []
        list.removeAll { $0 == trimmed }
        list.insert(trimmed, at: 0)
        if list.count > maxCount {
            list = Array(list.prefix(maxCount))
        }
        UserDefaults.standard.set(list, forKey: udKey)
    }

    public static var localIdentifiers: [String] {
        UserDefaults.standard.stringArray(forKey: udKey) ?? []
    }

}
