import Foundation

public enum MCSGuidePageStyle: Hashable {
    case story
    case castLead
}

public struct MCSGuide: Hashable {

    public var id: String = UUID().uuidString

    public var media: String = ""

    public var title: String = ""

    public var detail: String = ""

    public var handleBtnTitle: String = ""

    public var pageStyle: MCSGuidePageStyle = .story

}

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
