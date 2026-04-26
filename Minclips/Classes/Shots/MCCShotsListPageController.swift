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

    public var mcsv_labelItem: MCSFeedLabelItem!

    public var mcsv_index: Int = 0

    public var mcsv_onListDidAppear: (() -> Void)?

    private var mcsv_pagingScrollCallback: ((UIScrollView) -> Void)?

    private var mcsv_listState = MCCShotsListState()

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = .clear
        contentView.mcsv_collectionView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mcsv_collectionView
        cv.dataSource = self
        cv.delegate = self

        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcsv_loadList(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header

        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.mcsv_loadList(kind: .loadMore)
        }
        cv.mj_footer = footer
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        guard mcsv_labelItem != nil else { return }
        mcsv_loadList(kind: .initial)
    }

}

extension MCCShotsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcsv_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcsv_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcsv_onListDidAppear?()
    }

}

extension MCCShotsListPageController {

    public func mcsv_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcsv_pagingScrollCallback?(scrollView)
    }

}

// MARK: - 列表请求（本页自管）

extension MCCShotsListPageController {

    private var mcsv_refId: String { mcsv_labelItem.templateRef }

    private func mcsv_loadList(kind: MCCShotsListLoadKind) {
        guard mcsv_labelItem != nil else { return }
        var st = mcsv_listState
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

        let refId = mcsv_refId

        if kind == .loadMore {
            st.isLoadingMore = true
            mcsv_listState = st
            mcsv_applyListUI()
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
                        self.mcsv_listState.isLoadingMore = false
                        self.mcsv_applyListUI()
                    },
                    receiveValue: { [weak self] list in
                        guard let self = self else { return }
                        self.mcsv_listState.isLoadingMore = false
                        self.mcsv_listState.items += list.items
                        self.mcsv_listState.hasMore = list.items.count >= 20
                        self.mcsv_applyListUI()
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
                    self.mcsv_listState.listState = state
                    if let m = state.model, !state.isLoading, state.error == nil {
                        var list = m.items
                        if list.isEmpty {
                            list = Self.mcsv_mockFeedItems()
                        }
                        self.mcsv_listState.items = list
                        self.mcsv_listState.hasMore = list.count >= 20
                    }
                    self.mcsv_applyListUI()
                }
                .store(in: &cancellables)
        }
    }

    private func mcsv_applyListUI() {
        let st = mcsv_listState
        let items = st.items
        let listState = st.listState
        let isLoadingMore = st.isLoadingMore
        let hasMore = st.hasMore
        let cv = contentView.mcsv_collectionView
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

    private static func mcsv_mockFeedItems() -> [MCSFeedItem] {
        (0..<10).map { i in
            var it = MCSFeedItem()
            it.itemId = "mock_shot_\(i)"
            return it
        }
    }

    private static func mcsv_placeholderHex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars {
            h = h &* 31 &+ UInt(c.value)
        }
        return String(format: "%06X", h % 0xFFFFFF)
    }

    private func mcsv_styleListCell(_ cell: MCCShotsListItemCell, item: MCSFeedItem) {
        let hex = Self.mcsv_placeholderHex(from: item.itemId)
        cell.mcsv_imageContainer.backgroundColor = UIColor(hex: hex) ?? .darkGray
        cell.mcsv_durationLabel.text = " 00:00 "
        cell.mcsv_durationLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        cell.mcsv_durationLabel.textColor = .white
        cell.mcsv_durationLabel.backgroundColor = UIColor(white: 0, alpha: 0.45)
        cell.mcsv_durationLabel.layer.cornerRadius = 4
        cell.mcsv_durationLabel.clipsToBounds = true
        cell.mcsv_durationLabel.textAlignment = .center
        cell.mcsv_proBadge.isHidden = true
        cell.mcsv_proBadge.backgroundColor = UIColor(white: 0, alpha: 0.4)
        cell.mcsv_proBadge.layer.cornerRadius = 12
        cell.mcsv_proBadge.clipsToBounds = true
        cell.mcsv_proIcon.tintColor = .systemYellow
        cell.mcsv_proIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        cell.mcsv_titleLabel.text = item.itemId
        cell.mcsv_titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        cell.mcsv_titleLabel.textColor = UIColor(hex: "FFFFFF")!
        cell.mcsv_titleLabel.numberOfLines = 2
    }

}

// MARK: - Collection

extension MCCShotsListPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcsv_listState.items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsListItemCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsListItemCell
        if let item = mcsv_listState.items[safe: indexPath.item] {
            mcsv_styleListCell(cell, item: item)
        }
        return cell
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
        mcsv_forwardPagingScroll(scrollView)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
