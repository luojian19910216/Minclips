import UIKit
import SDWebImage
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

    private var mcvc_appliedItemIds: [String] = []

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = .clear
        contentView.mcvw_collectionView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mcvw_collectionView
        contentView.mcvw_waterfallLayout.delegate = self
        cv.dataSource = self
        cv.delegate = self
        cv.prefetchDataSource = self

        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcvc_loadList(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header

        cv.mj_footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.mcvc_loadList(kind: .loadMore)
        }
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
            mcvc_syncListChromeOnly()
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
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    guard let self = self else { return }
                    self.mcvc_listState.listState = state
                    if let m = state.model, !state.isLoading, state.error == nil {
                        var list = m.items
                        self.mcvc_listState.items = list
                        self.mcvc_listState.hasMore = list.count >= 20
                    }
                    self.mcvc_applyListUI()
                }
                .store(in: &cancellables)
        }
    }

    private func mcvc_applyListUI() {
        mcvc_syncListChromeOnly()
        mcvc_reloadCollectionItemsIfNeeded()
    }

    private func mcvc_syncListChromeOnly() {
        let st = mcvc_listState
        let items = st.items
        let listState = st.listState
        let isLoadingMore = st.isLoadingMore
        let hasMore = st.hasMore
        let cv = contentView.mcvw_collectionView
        contentView.mcvw_setListSkeletonVisible(listState.isLoading && items.isEmpty)
        if listState.isLoading && items.isEmpty {
            cv.mj_footer?.isHidden = true
        }
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
    }

    private func mcvc_reloadCollectionItemsIfNeeded() {
        let cv = contentView.mcvw_collectionView
        let items = mcvc_listState.items
        let newIds = items.map(\.itemId)
        if newIds == mcvc_appliedItemIds {
            return
        }
        let oldIds = mcvc_appliedItemIds
        if !oldIds.isEmpty,
           newIds.count > oldIds.count,
           Array(newIds.prefix(oldIds.count)) == oldIds {
            mcvc_appliedItemIds = newIds
            let start = oldIds.count
            let indexPaths = (start..<newIds.count).map { IndexPath(item: $0, section: 0) }
            cv.performBatchUpdates({
                cv.insertItems(at: indexPaths)
            }, completion: { [weak self] ok in
                guard let self = self, !ok else { return }
                self.mcvc_appliedItemIds = self.mcvc_listState.items.map(\.itemId)
                cv.reloadData()
            })
            return
        }
        mcvc_appliedItemIds = newIds
        cv.reloadData()
    }

    private static func mcvc_placeholderHex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars {
            h = h &* 31 &+ UInt(c.value)
        }
        return String(format: "%06X", h % 0xFFFFFF)
    }

    private static func mcvc_formatVideoDurationLabel(seconds: Int) -> String {
        let sec = max(0, seconds)
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        let inner: String
        if h > 0 {
            inner = String(format: "%d:%02d:%02d", h, m, s)
        } else {
            inner = String(format: "%d:%02d", m, s)
        }
        return " \(inner) "
    }

    private func mcvc_feedThumbnailPixelSize(forCollectionWidth width: CGFloat, video: MCSFeedVideoAssetShell) -> CGSize {
        let layout = contentView.mcvw_waterfallLayout
        let w = width > 0 ? width : UIScreen.main.bounds.width
        let inner = w - layout.sectionInset.left - layout.sectionInset.right
        let cols = max(1, layout.columnCount)
        let colW = (inner - CGFloat(cols - 1) * layout.minimumInteritemSpacing) / CGFloat(cols)
        let ratio = MCCShotsListItemMetrics.imageHeightPerWidth(videoAsset: video)
        return MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: max(1, colW), heightPerWidth: ratio)
    }

    private func mcvc_styleListCell(_ cell: MCCShotsListItemCell, item: MCSFeedItem, collectionView: UICollectionView) {
        let hex = Self.mcvc_placeholderHex(from: item.itemId)
        cell.mcvw_imageContainer.backgroundColor = UIColor(hex: hex) ?? .darkGray
        let a = item.videoAsset
        cell.mcvw_setImageHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth(videoAsset: a))
        let thumbPx = mcvc_feedThumbnailPixelSize(forCollectionWidth: collectionView.bounds.width, video: a)
        cell.mcvw_applyPosterOnly(posterUrl: a.posterImageUrl, thumbnailPixelSize: thumbPx)
        let durationSec = item.videoAsset.duration
        if durationSec > 0 {
            cell.mcvw_durationLabel.text = Self.mcvc_formatVideoDurationLabel(seconds: durationSec)
            cell.mcvw_durationLabel.isHidden = false
        } else {
            cell.mcvw_durationLabel.isHidden = true
        }
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
        cell.mcvw_titleLabel.attributedText = NSAttributedString(
            string: item.itemTitle,
            attributes: MCCShotsListItemMetrics.titleTextAttributes(textColor: .white)
        )
    }

    private func mcvc_heightForItem(_ item: MCSFeedItem, itemWidth: CGFloat) -> CGFloat {
        let m = MCCShotsListItemMetrics.self
        let title = item.itemTitle
        let ratio = m.imageHeightPerWidth(videoAsset: item.videoAsset)
        let imageH = itemWidth * ratio
        let attrs = MCCShotsListItemMetrics.titleTextAttributes(textColor: UIColor.hex_d3d0cd)
        let maxTextH = ceil(m.titleLineHeight * CGFloat(m.titleMaxLines))
        let textH = min(
            ceil(
                (title as NSString).boundingRect(
                    with: CGSize(width: itemWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                ).height
            ),
            maxTextH
        )
        return imageH + m.imageToTitleSpacing + textH
    }

}

extension MCCShotsListPageController: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_listState.items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId, for: indexPath
        ) as! MCCShotsListItemCell
        if let item = mcvc_listState.items[safe: indexPath.item] {
            mcvc_styleListCell(cell, item: item, collectionView: collectionView)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = mcvc_listState.items[safe: indexPath.item] else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        let vc = MCCFeedDetailController()
        vc.mcvc_feedItem = item
        if let cell = collectionView.cellForItem(at: indexPath) as? MCCShotsListItemCell {
            vc.mcvc_webpHandoff = cell.mcvw_captureWebpPlaybackHandoff()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? MCCShotsListItemCell,
              let item = mcvc_listState.items[safe: indexPath.item] else { return }
        let thumbPx = mcvc_feedThumbnailPixelSize(forCollectionWidth: collectionView.bounds.width, video: item.videoAsset)
        cell.mcvw_applyWebpAnimated(webpUrl: item.videoAsset.webpImageUrl, thumbnailPixelSize: thumbPx)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? MCCShotsListItemCell)?.mcvw_clearWebpAnimated()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcvc_forwardPagingScroll(scrollView)
    }

}

extension MCCShotsListPageController: UICollectionViewDataSourcePrefetching {

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let items = mcvc_listState.items
        let cvW = collectionView.bounds.width
        let cvWidth = cvW > 0 ? cvW : view.bounds.width
        for indexPath in indexPaths {
            guard let item = items[safe: indexPath.item] else { continue }
            let s = item.videoAsset.posterImageUrl
            guard !s.isEmpty, let u = URL(string: s) else { continue }
            let thumbPx = mcvc_feedThumbnailPixelSize(forCollectionWidth: cvWidth, video: item.videoAsset)
            let ctx = MCCShotsListItemMetrics.sdPosterThumbnailContext(thumbnailPixelSize: thumbPx)
            SDWebImagePrefetcher.shared.prefetchURLs(
                [u],
                options: MCCShotsListItemMetrics.sdPosterLoadOptions,
                context: ctx,
                progress: nil,
                completed: nil
            )
        }
    }

}

extension MCCShotsListPageController: MCCShotsWaterfallLayoutDelegate {

    public func waterfallLayout(
        _ layout: MCCShotsWaterfallLayout,
        heightForItemAt indexPath: IndexPath,
        itemWidth: CGFloat
    ) -> CGFloat {
        guard let item = mcvc_listState.items[safe: indexPath.item] else { return 1 }
        return mcvc_heightForItem(item, itemWidth: itemWidth)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
