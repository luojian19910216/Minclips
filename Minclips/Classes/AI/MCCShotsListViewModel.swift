//
//  MCCShotsListViewModel.swift
//

import Foundation
import Combine
import Data
import Common

public enum MCCShotsListLoadKind: Sendable {
    case initial
    case pullToRefresh
    case loadMore
}

public final class MCCShotsListViewModel: MCCBaseViewModel, ObservableObject {

    public var labelItem = MCSFeedLabelItem()

    @Published public private(set) var items: [MCSFeedItem] = []
    @Published public private(set) var hasMore: Bool = false
    @Published public private(set) var listState = MCSLoadState<MCSList<MCSFeedItem>>()
    @Published public private(set) var isLoadingMore: Bool = false

    public var mcsv_listPageSize: Int { 20 }

    public var mcsv_refId: String { labelItem.templateRef }

    public func mcsv_load(kind: MCCShotsListLoadKind) {
        let refId = labelItem.templateRef
        switch kind {
        case .initial:
            if !items.isEmpty { return }
            if listState.isLoading { return }
        case .pullToRefresh:
            if listState.isLoading { return }
        case .loadMore:
            if !hasMore { return }
            if listState.isLoading { return }
            if isLoadingMore { return }
        }

        if kind == .loadMore {
            mcsv_loadMorePage(refId: refId)
        } else {
            mcsv_loadFirstOrRefreshPage(refId: refId)
        }
    }

    private func mcsv_loadFirstOrRefreshPage(refId: String) {
        var request = MCSFeedListRequest()
        request.itemsPerPage = mcsv_listPageSize
        request.customRefId = refId

        MCCFeedAPIManager.shared.customItems(with: request)
            .asLoadState()
            .sink { [weak self] state in
                guard let self = self else { return }
                self.listState = state
                if let m = state.model, !state.isLoading {
                    self.items = m.items
                    self.hasMore = m.items.count >= self.mcsv_listPageSize
                }
            }
            .store(in: &cancellables)
    }

    private func mcsv_loadMorePage(refId: String) {
        isLoadingMore = true
        var request = MCSFeedListRequest()
        request.itemsPerPage = mcsv_listPageSize
        request.customRefId = refId
        if let last = items.last, !last.itemId.isEmpty {
            request.resumeAfterId = last.itemId
        }

        MCCFeedAPIManager.shared.customItems(with: request)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isLoadingMore = false
                },
                receiveValue: { [weak self] list in
                    guard let self = self else { return }
                    self.isLoadingMore = false
                    self.items += list.items
                    self.hasMore = list.items.count >= self.mcsv_listPageSize
                }
            )
            .store(in: &cancellables)
    }
}
