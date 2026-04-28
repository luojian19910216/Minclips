import UIKit
import SnapKit
import MJRefresh
import JXPagingView
import Combine
import Common
import Data
import SDWebImage

private enum MCCProjectsListLayout {
    static let pageSize = 20
}

private struct MCCProjectListState {
    var runItems: [MCSRunItem] = []
    var feedItems: [MCSFeedItem] = []
    var runLoadState: MCSLoadState<MCSList<MCSRunItem>> = MCSLoadState()
    var feedLoadState: MCSLoadState<MCSList<MCSFeedItem>> = MCSLoadState()
    var favorNextPageIndex: Int = 1
    var hasMore: Bool = false
    var isLoadingMore: Bool = false

    func itemCount(isLikes: Bool) -> Int {
        isLikes ? feedItems.count : runItems.count
    }

    func primaryIsLoading(isLikes: Bool) -> Bool {
        isLikes ? feedLoadState.isLoading : runLoadState.isLoading
    }
}

private enum MCCProjectListLoadKind: Sendable {
    case initial
    case pullToRefresh
    case loadMore
}

/// Likes 瀑布流标题：13 regular，白色（与首页 14 区分）。
private enum MCCProjectsLikesListMetrics {
    static let titleLineHeight: CGFloat = 15

    static func titleTextAttributes(textColor: UIColor = .white) -> [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle()
        p.minimumLineHeight = titleLineHeight
        p.maximumLineHeight = titleLineHeight
        let font = UIFont.systemFont(ofSize: 13, weight: .regular)
        return [.font: font, .paragraphStyle: p, .foregroundColor: textColor]
    }
}

// MARK: - Controller

public final class MCCProjectsListPageController: MCCViewController<MCCProjectsListPageView, MCCEmptyViewModel> {

    public var mcpj_segment: MCCProjectSegment!
    public var mcpj_index: Int = 0
    public var mcpj_onListDidAppear: (() -> Void)?

    private var mcpj_pagingScrollCallback: ((UIScrollView) -> Void)?
    private var mcpj_listState = MCCProjectListState()

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
        if mcpj_isLikes {
            contentView.mcvp_activateLikesWaterfallLikeHome()
            contentView.mcvw_likesWaterfallLayout.delegate = self
            cv.prefetchDataSource = self
        }
        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcpj_load(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header
        cv.mj_footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.mcpj_load(kind: .loadMore)
        }
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        guard mcpj_segment != nil else { return }
        mcpj_load(kind: .initial)
    }
}

extension MCCProjectsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcvw_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcpj_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcpj_onListDidAppear?()
    }
}

// MARK: - Paging ↔ tab

extension MCCProjectsListPageController {

    public func mcpj_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcpj_pagingScrollCallback?(scrollView)
    }

    private var mcpj_isLikes: Bool {
        (mcpj_segment?.ref ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "likes"
    }

    /// 是否允许发起本次加载（防抖 / 分页边界）。
    private func mcpj_canFetch(_ kind: MCCProjectListLoadKind) -> Bool {
        let s = mcpj_listState
        let lk = mcpj_isLikes
        switch kind {
        case .initial:
            if lk {
                return s.feedItems.isEmpty && !s.feedLoadState.isLoading
            }
            return s.runItems.isEmpty && !s.runLoadState.isLoading
        case .pullToRefresh:
            return lk ? !s.feedLoadState.isLoading : !s.runLoadState.isLoading
        case .loadMore:
            guard s.hasMore, !s.isLoadingMore else { return false }
            return lk ? !s.feedLoadState.isLoading : !s.runLoadState.isLoading
        }
    }
}

// MARK: - Network

private extension MCCProjectsListPageController {

    func mcpj_load(kind: MCCProjectListLoadKind) {
        guard mcpj_segment != nil, mcpj_canFetch(kind) else { return }
        if mcpj_isLikes {
            mcpj_loadLikes(kind)
        } else {
            mcpj_loadRuns(kind)
        }
    }

    func mcpj_beginLoadMore() {
        mcpj_listState.isLoadingMore = true
        mcpj_applyListUI()
    }

    func mcpj_endLoadMore() {
        mcpj_listState.isLoadingMore = false
        mcpj_applyListUI()
    }

    func mcpj_loadRuns(_ kind: MCCProjectListLoadKind) {
        if kind == .loadMore {
            mcpj_beginLoadMore()
            var request = MCSRunListRequest()
            request.itemsPerPage = MCCProjectsListLayout.pageSize
            let lastId = mcpj_listState.runItems.last?.runId
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !lastId.isEmpty {
                request.resumeAfterId = lastId
            }
            MCCRunAPIManager.shared.inventory(with: request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] _ in self?.mcpj_endLoadMore() },
                    receiveValue: { [weak self] page in
                        guard let self else { return }
                        self.mcpj_listState.runItems.append(contentsOf: page.items)
                        self.mcpj_listState.hasMore = page.items.count >= MCCProjectsListLayout.pageSize
                    }
                )
                .store(in: &cancellables)
            return
        }

        var request = MCSRunListRequest()
        request.itemsPerPage = MCCProjectsListLayout.pageSize
        MCCRunAPIManager.shared.inventory(with: request)
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.mcpj_listState.runLoadState = state
                if let m = state.model, !state.isLoading, state.error == nil {
                    self.mcpj_listState.runItems = m.items
                    self.mcpj_listState.hasMore = m.items.count >= MCCProjectsListLayout.pageSize
                }
                self.mcpj_applyListUI()
            }
            .store(in: &cancellables)
    }

    func mcpj_loadLikes(_ kind: MCCProjectListLoadKind) {
        let pageSz = MCCProjectsListLayout.pageSize

        if kind == .loadMore {
            mcpj_beginLoadMore()
            var request = MCSFeedLikeListRequest()
            request.itemsPerPage = pageSz
            request.pageIndex = mcpj_listState.favorNextPageIndex
            MCCFeedAPIManager.shared.favorInventory(with: request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] _ in self?.mcpj_endLoadMore() },
                    receiveValue: { [weak self] page in
                        guard let self else { return }
                        self.mcpj_listState.feedItems.append(contentsOf: page.items)
                        self.mcpj_listState.hasMore = page.items.count >= pageSz
                        self.mcpj_listState.favorNextPageIndex += 1
                    }
                )
                .store(in: &cancellables)
            return
        }

        if kind == .pullToRefresh || kind == .initial {
            mcpj_listState.favorNextPageIndex = 1
            mcpj_listState.feedItems = []
            mcpj_listState.hasMore = false
        }

        var request = MCSFeedLikeListRequest()
        request.itemsPerPage = pageSz
        request.pageIndex = 1
        MCCFeedAPIManager.shared.favorInventory(with: request)
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.mcpj_listState.feedLoadState = state
                if let m = state.model, !state.isLoading, state.error == nil {
                    self.mcpj_listState.feedItems = m.items
                    let full = m.items.count >= pageSz
                    self.mcpj_listState.hasMore = full
                    self.mcpj_listState.favorNextPageIndex = full ? 2 : 1
                }
                self.mcpj_applyListUI()
            }
            .store(in: &cancellables)
    }

    func mcpj_applyListUI() {
        let st = mcpj_listState
        let likes = mcpj_isLikes
        let count = st.itemCount(isLikes: likes)
        let loading = st.primaryIsLoading(isLikes: likes)
        let cv = contentView.mcvw_collectionView

        contentView.mcvw_setListSkeletonVisible(loading && count == 0)

        if loading && count == 0 {
            cv.mj_footer?.isHidden = true
        } else if !loading {
            cv.mj_header?.endRefreshing()
            mcpj_syncFooter(cv, itemCount: count, hasMore: st.hasMore, loadingMore: st.isLoadingMore)
        }
        cv.isHidden = false
        cv.reloadData()
    }

    func mcpj_syncFooter(_ cv: UICollectionView, itemCount: Int, hasMore: Bool, loadingMore: Bool) {
        guard itemCount > 0 else {
            cv.mj_footer?.isHidden = true
            return
        }
        cv.mj_footer?.isHidden = false
        guard !loadingMore else { return }
        if hasMore {
            cv.mj_footer?.resetNoMoreData()
            cv.mj_footer?.endRefreshing()
        } else {
            cv.mj_footer?.endRefreshingWithNoMoreData()
        }
    }
}

// MARK: - Collection view

extension MCCProjectsListPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcpj_isLikes ? mcpj_listState.feedItems.count : mcpj_listState.runItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if mcpj_isLikes {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId, for: indexPath
            ) as! MCCShotsListItemCell
            if let feed = mcpj_listState.feedItems[safe: indexPath.item] {
                mcpj_styleLikesCell(cell, item: feed, collectionView: collectionView)
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId, for: indexPath
        ) as! MCCProjectsRunCell
        if let run = mcpj_listState.runItems[safe: indexPath.item] {
            cell.mcpj_apply(run: run)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if mcpj_isLikes, let feed = mcpj_listState.feedItems[safe: indexPath.item] {
            let vc = MCCFeedDetailController()
            vc.mcvc_feedItem = feed
            if let cell = collectionView.cellForItem(at: indexPath) as? MCCShotsListItemCell {
                vc.mcvc_webpHandoff = cell.mcvw_captureWebpPlaybackHandoff()
            }
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        guard let run = mcpj_listState.runItems[safe: indexPath.item] else { return }
        let title = run.runId.isEmpty ? "Project" : run.runId
        let kind: MCCCreationResultKind = indexPath.item % 2 == 0 ? .successImage : .successVideo(totalDuration: 15)
        let vc = MCCCreationResultController(navigationTitle: title, kind: kind, workRef: run.runId)
        navigationController?.pushViewController(vc, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard mcpj_isLikes,
              let cell = cell as? MCCShotsListItemCell,
              let item = mcpj_listState.feedItems[safe: indexPath.item] else { return }
        let thumbPx = mcpj_likesThumbnailPixelSize(forCollectionWidth: collectionView.bounds.width)
        cell.mcvw_applyWebpAnimated(webpUrl: item.videoAsset.webpImageUrl, thumbnailPixelSize: thumbPx)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard mcpj_isLikes else { return }
        (cell as? MCCShotsListItemCell)?.mcvw_clearWebpAnimated()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard mcpj_isLikes == false,
              let flow = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 100, height: 160)
        }
        let columns = 3
        let inset = flow.sectionInset
        let spacing = flow.minimumInteritemSpacing
        let inner = collectionView.bounds.width - inset.left - inset.right
        let w = (inner - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        if w <= 0 { return CGSize(width: 100, height: 160) }
        // Runs 封面：宽高 120×160（竖图），仅图片无文案 → 单元格高度 = 宽 × 160/120
        let h = w * 160 / 120
        return CGSize(width: floor(w), height: floor(h))
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcpj_forwardPagingScroll(scrollView)
    }
}

extension MCCProjectsListPageController: UICollectionViewDataSourcePrefetching {

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard mcpj_isLikes else { return }
        let items = mcpj_listState.feedItems
        let cvW = collectionView.bounds.width
        let cvWidth = cvW > 0 ? cvW : view.bounds.width
        for indexPath in indexPaths {
            guard let item = items[safe: indexPath.item] else { continue }
            let s = item.videoAsset.posterImageUrl
            guard !s.isEmpty, let u = URL(string: s) else { continue }
            let thumbPx = mcpj_likesThumbnailPixelSize(forCollectionWidth: cvWidth)
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

extension MCCProjectsListPageController: MCCShotsWaterfallLayoutDelegate {

    public func waterfallLayout(
        _ layout: MCCShotsWaterfallLayout,
        heightForItemAt indexPath: IndexPath,
        itemWidth: CGFloat
    ) -> CGFloat {
        guard mcpj_isLikes, let item = mcpj_listState.feedItems[safe: indexPath.item] else { return 1 }
        return mcpj_heightForLikesItem(item, itemWidth: itemWidth)
    }
}

private extension MCCProjectsListPageController {

    func mcpj_likesThumbnailPixelSize(forCollectionWidth width: CGFloat) -> CGSize {
        let colW = contentView.mcvp_likesWaterfallColumnWidth(collectionWidth: width)
        return MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: colW)
    }

    func mcpj_styleLikesCell(_ cell: MCCShotsListItemCell, item: MCSFeedItem, collectionView: UICollectionView) {
        cell.mcvw_imageContainer.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        let a = item.videoAsset
        cell.mcvw_setImageHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        let thumbPx = mcpj_likesThumbnailPixelSize(forCollectionWidth: collectionView.bounds.width)
        cell.mcvw_applyPosterOnly(posterUrl: a.posterImageUrl, thumbnailPixelSize: thumbPx)
        let displaySeconds = item.tenSecondMode ? 10 : 5
        cell.mcvw_durationLabel.text = Self.mcpj_formatVideoDurationLabel(seconds: displaySeconds)
        cell.mcvw_durationLabel.isHidden = false
        cell.mcvw_durationLabel.font = .systemFont(ofSize: 11, weight: .regular)
        cell.mcvw_durationLabel.textColor = UIColor.white.withAlphaComponent(0.48)
        cell.mcvw_durationLabel.backgroundColor = .clear
        cell.mcvw_durationLabel.textAlignment = .natural
        let showPro = item.proFeature
        cell.mcvw_proBadge.isHidden = !showPro
        cell.mcvw_titleLabel.attributedText = NSAttributedString(
            string: item.itemTitle,
            attributes: MCCProjectsLikesListMetrics.titleTextAttributes(textColor: .white)
        )
    }

    func mcpj_heightForLikesItem(_ item: MCSFeedItem, itemWidth: CGFloat) -> CGFloat {
        let m = MCCShotsListItemMetrics.self
        let title = item.itemTitle
        let imageH = itemWidth * m.imageHeightPerWidth
        let attrs = MCCProjectsLikesListMetrics.titleTextAttributes()
        let maxTextH = ceil(MCCProjectsLikesListMetrics.titleLineHeight * CGFloat(m.titleMaxLines))
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

    static func mcpj_formatVideoDurationLabel(seconds: Int) -> String {
        let sec = max(0, seconds)
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        let inner: String
        if h > 0 {
            inner = String(format: "%d:%02d:%02d", h, m, s)
        } else {
            inner = String(format: "%02d:%02d", m, s)
        }
        return " \(inner) "
    }
}

// MARK: - Cell

private extension MCCProjectsRunCell {

    func mcpj_apply(run: MCSRunItem) {
        mcvw_imageContainer.backgroundColor = UIColor(hex: Self.mcpj_hex(from: run.runId)) ?? .darkGray
        mcvw_thumbView.sd_cancelCurrentImageLoad()
        mcvw_thumbView.image = nil
    }

    static func mcpj_hex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars { h = h &* 31 &+ UInt(c.value) }
        return String(format: "%06X", h % 0xFFFFFF)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

// MARK: - Segment model

public struct MCCProjectSegment: Equatable {
    public var ref: String
    public var title: String

    public init(ref: String, title: String) {
        self.ref = ref
        self.title = title
    }
}
