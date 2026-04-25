//
//  MCCShotsViewModel.swift
//  标签与列表分步拉取；Mock 可模拟失败，后续可替换为真实 Data 层。
//

import Foundation
import Combine

public struct MCCShotTag: Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
}

public struct MCCShotItem: Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let durationText: String
    public let isPro: Bool
    public let mockThumbHex: String
}

public enum MCCShotsTagsPhase: Equatable, Sendable {
    case idle
    case loading
    case success
    case failure(String)
}

public final class MCCShotsViewModel: MCCBaseViewModel, ObservableObject {

    @Published public private(set) var tagsPhase: MCCShotsTagsPhase = .idle
    @Published public private(set) var tags: [MCCShotTag] = []
    @Published public private(set) var selectedTagIndex: Int = 0

    /// 各 tag 对应列表，未请求过可不含 key
    @Published public private(set) var listByTagId: [String: [MCCShotItem]] = [:]
    /// 正在拉列表的 tag（用于骨架/菊花）
    @Published public private(set) var listLoadingTagIds: Set<String> = []
    @Published public private(set) var listErrorByTagId: [String: String] = [:]

    /// DEBUG 下可置 true 以概率失败标签请求，便于自测
    public var mcsv_debugSimulateTagFailure: Bool = false

    // MARK: - 标签

    /// 拉标签；成功后会自动用 **第一个** 标签拉取列表；失败不拉列表。
    public func mcsv_loadTags() {
        tagsPhase = .loading
        tags = []
        listByTagId = [:]
        listErrorByTagId = [:]
        listLoadingTagIds = []
        selectedTagIndex = 0

        let delay: TimeInterval = 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            #if DEBUG
            if self.mcsv_debugSimulateTagFailure, Bool.random() {
                self.tagsPhase = .failure("标签加载失败，请重试")
                return
            }
            #endif
            let t = MCCShotsViewModel.mcsv_mockTags
            self.tags = t
            self.tagsPhase = .success
            guard let first = t.first else { return }
            self.mcsv_loadList(tagId: first.id, isUserRefresh: false)
        }
    }

    public func mcsv_selectTag(at index: Int) {
        guard index >= 0, index < tags.count else { return }
        selectedTagIndex = index
        let id = tags[index].id
        if listByTagId[id] == nil, !listLoadingTagIds.contains(id) {
            mcsv_loadList(tagId: id, isUserRefresh: false)
        }
    }

    // MARK: - 列表

    /// 拉指定 tag 的列表；已缓存且非用户主动刷新时可直接用缓存（由调用方控制）。
    public func mcsv_loadList(tagId: String, isUserRefresh: Bool) {
        if !isUserRefresh, listByTagId[tagId] != nil { return }
        if listLoadingTagIds.contains(tagId) { return }

        var err = listErrorByTagId
        err.removeValue(forKey: tagId)
        listErrorByTagId = err

        var loading = listLoadingTagIds
        loading.insert(tagId)
        listLoadingTagIds = loading

        let delay: TimeInterval = 0.45
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            var ld = self.listLoadingTagIds
            ld.remove(tagId)
            self.listLoadingTagIds = ld

            #if DEBUG
            if self.mcsv_debugSimulateTagFailure, self.tags.count > 1, tagId == self.tags[1].id, Bool.random() {
                var e = self.listErrorByTagId
                e[tagId] = "列表加载失败，下拉重试"
                self.listErrorByTagId = e
                return
            }
            #endif
            var d = self.listByTagId
            d[tagId] = MCCShotsViewModel.mcsv_mockItems(forTagId: tagId)
            self.listByTagId = d
            var e = self.listErrorByTagId
            e.removeValue(forKey: tagId)
            self.listErrorByTagId = e
        }
    }

    public var mcsv_currentTagId: String? {
        tags[safe: selectedTagIndex]?.id
    }
}

// MARK: - Mock

public extension MCCShotsViewModel {

    static let mcsv_mockTags: [MCCShotTag] = [
        .init(id: "t1", title: "Trending"),
        .init(id: "t2", title: "All"),
        .init(id: "t3", title: "New"),
        .init(id: "t4", title: "Singer"),
        .init(id: "t5", title: "Actor"),
        .init(id: "t6", title: "Story")
    ]

    static func mcsv_mockItems(forTagId tagId: String) -> [MCCShotItem] {
        let base = MCCShotsViewModel.mcsv_baseMock
        return base.enumerated().map { i, m in
            MCCShotItem(
                id: m.id + "-" + tagId,
                title: m.title,
                durationText: m.durationText,
                isPro: m.isPro,
                mockThumbHex: m.mockThumbHex
            )
        }
    }

    private static let mcsv_baseMock: [MCCShotItem] = [
        .init(id: "nb", title: "Night Beach", durationText: "00:05", isPro: false, mockThumbHex: "0D1B2A"),
        .init(id: "ros", title: "Ritual of Silver and Still Water", durationText: "00:10", isPro: true, mockThumbHex: "1B263B"),
        .init(id: "sp", title: "Spotlight", durationText: "00:08", isPro: true, mockThumbHex: "2C3E50"),
        .init(id: "bow", title: "Silent Arrow", durationText: "00:06", isPro: true, mockThumbHex: "22333A")
    ]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
