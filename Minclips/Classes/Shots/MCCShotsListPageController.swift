import UIKit
import SnapKit
import MJRefresh
import JXPagingView
import Combine
import Common
import Data

private struct MCCShotsListState {

    var items: [MCSFeedItem] = []

    var hasMore: Bool = false

    var listState: MCSLoadState<MCSList<MCSFeedItem>> = MCSLoadState()

    var isLoadingMore: Bool = false

}

private enum MCCShotsListLoadKind: Sendable {
    case initial
    case pullToRefresh
    case loadMore
}

public final class MCCShotsListPageController: MCCViewController<MCCShotsListPageView, MCCEmptyViewModel> {

    public var mcvc_labelItem: MCSFeedLabelItem!

    public var mcvc_index: Int = 0

    public var mcvc_onListDidAppear: (() -> Void)?

    private var mcvc_pagingScrollCallback: ((UIScrollView) -> Void)?

    private var mcvc_listState = MCCShotsListState()

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = .clear
        contentView.mcvw_collectionView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mcvw_collectionView
        cv.dataSource = self
        cv.delegate = self

        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcvc_loadList(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header

        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.mcvc_loadList(kind: .loadMore)
        }
        cv.mj_footer = footer
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        guard mcvc_labelItem != nil else { return }
        mcvc_loadList(kind: .initial)
    }

}

extension MCCShotsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcvw_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcvc_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcvc_onListDidAppear?()
    }

}

extension MCCShotsListPageController {

    public func mcvc_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcvc_pagingScrollCallback?(scrollView)
    }

}

extension MCCShotsListPageController {

    private var mcvc_refId: String { mcvc_labelItem.templateRef }

    private func mcvc_loadList(kind: MCCShotsListLoadKind) {
        guard mcvc_labelItem != nil else { return }
        var st = mcvc_listState
        switch kind {
        case .initial:
            if !st.items.isEmpty { return }
            if st.listState.isLoading { return }
        case .pullToRefresh:
            if st.listState.isLoading { return }
        case .loadMore:
            if !st.hasMore { return }
            if st.listState.isLoading { return }
            if st.isLoadingMore { return }
        }

        let refId = mcvc_refId

        if kind == .loadMore {
            st.isLoadingMore = true
            mcvc_listState = st
            mcvc_applyListUI()
            var request = MCSFeedListRequest()
            request.itemsPerPage = 20
            request.customRefId = refId
            if let last = st.items.last, !last.itemId.isEmpty {
                request.resumeAfterId = last.itemId
            }
            MCCFeedAPIManager.shared.customItems(with: request)
                .sink(
                    receiveCompletion: { [weak self] _ in
                        guard let self = self else { return }
                        self.mcvc_listState.isLoadingMore = false
                        self.mcvc_applyListUI()
                    },
                    receiveValue: { [weak self] list in
                        guard let self = self else { return }
                        self.mcvc_listState.isLoadingMore = false
                        self.mcvc_listState.items += list.items
                        self.mcvc_listState.hasMore = list.items.count >= 20
                        self.mcvc_applyListUI()
                    }
                )
                .store(in: &cancellables)
        } else {
            var request = MCSFeedListRequest()
            request.itemsPerPage = 20
            request.customRefId = refId
            MCCFeedAPIManager.shared.customItems(with: request)
                .asLoadState()
                .sink { [weak self] state in
                    guard let self = self else { return }
                    self.mcvc_listState.listState = state
                    if let m = state.model, !state.isLoading, state.error == nil {
                        var list = m.items
                        if list.isEmpty {
                            list = Self.mcvc_mockFeedItems()
                        }
                        self.mcvc_listState.items = list
                        self.mcvc_listState.hasMore = list.count >= 20
                    }
                    self.mcvc_applyListUI()
                }
                .store(in: &cancellables)
        }
    }

    private func mcvc_applyListUI() {
        let st = mcvc_listState
        let items = st.items
        let listState = st.listState
        let isLoadingMore = st.isLoadingMore
        let hasMore = st.hasMore
        let cv = contentView.mcvw_collectionView
        if !listState.isLoading {
            cv.mj_header?.endRefreshing()
        }
        if !listState.isLoading {
            if items.isEmpty {
                cv.mj_footer?.isHidden = true
            } else {
                cv.mj_footer?.isHidden = false
                if !isLoadingMore {
                    if hasMore {
                        cv.mj_footer?.resetNoMoreData()
                        cv.mj_footer?.endRefreshing()
                    } else {
                        cv.mj_footer?.endRefreshingWithNoMoreData()
                    }
                }
            }
        }
        cv.isHidden = false
        cv.reloadData()
    }

    private static func mcvc_mockFeedItems() -> [MCSFeedItem] {
        (0..<10).map { i in
            var it = MCSFeedItem()
            it.itemId = "mock_shot_\(i)"
            return it
        }
    }

    private static func mcvc_placeholderHex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars {
            h = h &* 31 &+ UInt(c.value)
        }
        return String(format: "%06X", h % 0xFFFFFF)
    }

    private func mcvc_styleListCell(_ cell: MCCShotsListItemCell, item: MCSFeedItem) {
        let hex = Self.mcvc_placeholderHex(from: item.itemId)
        cell.mcvw_imageContainer.backgroundColor = UIColor(hex: hex) ?? .darkGray
        cell.mcvw_durationLabel.text = " 00:00 "
        cell.mcvw_durationLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        cell.mcvw_durationLabel.textColor = .white
        cell.mcvw_durationLabel.backgroundColor = UIColor(white: 0, alpha: 0.45)
        cell.mcvw_durationLabel.layer.cornerRadius = 4
        cell.mcvw_durationLabel.clipsToBounds = true
        cell.mcvw_durationLabel.textAlignment = .center
        cell.mcvw_proBadge.isHidden = true
        cell.mcvw_proBadge.backgroundColor = UIColor(white: 0, alpha: 0.4)
        cell.mcvw_proBadge.layer.cornerRadius = 12
        cell.mcvw_proBadge.clipsToBounds = true
        cell.mcvw_proIcon.tintColor = .systemYellow
        cell.mcvw_proIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        cell.mcvw_titleLabel.text = item.itemId
        cell.mcvw_titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        cell.mcvw_titleLabel.textColor = UIColor(hex: "FFFFFF")!
        cell.mcvw_titleLabel.numberOfLines = 2
    }

}

extension MCCShotsListPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_listState.items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId, for: indexPath
        ) as! MCCShotsListItemCell
        if let item = mcvc_listState.items[safe: indexPath.item] {
            mcvc_styleListCell(cell, item: item)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = mcvc_listState.items[safe: indexPath.item] else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        let vc = MCCFeedDetailController()
        vc.mcvc_feedItem = item
        navigationController?.pushViewController(vc, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset: CGFloat = 16
        let spacing: CGFloat = 8
        let w = (collectionView.bounds.width - inset * 2 - spacing) / 2
        if w <= 0 { return CGSize(width: 160, height: 220) }
        let thumbH = w * 4 / 3
        return CGSize(width: w, height: thumbH + 6 + 40)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcvc_forwardPagingScroll(scrollView)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
