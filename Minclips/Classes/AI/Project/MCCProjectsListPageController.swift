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

public final class MCCProjectsListPageController: MCCViewController<MCCProjectsListPageView, MCCEmptyViewModel> {

    public var mcvc_projectSegment: MCCProjectSegment!
    public var mcvc_pageIndex: Int = 0
    public var mcvc_onListDidAppear: (() -> Void)?

    private var mcvc_pagingScrollCallback: ((UIScrollView) -> Void)?
    private var mcvc_listState = MCCProjectListState()

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = .clear
        contentView.mcvw_collectionView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        contentView.mcvw_configureListSkeleton(isLikesLayout: mcvc_isLikes)
        let cv = contentView.mcvw_collectionView
        cv.dataSource = self
        cv.delegate = self
        if mcvc_isLikes {
            contentView.mcvw_activateLikesWaterfallLikeHome()
            contentView.mcvw_likesWaterfallLayout.delegate = self
            cv.prefetchDataSource = self
        } else {
            contentView.mcvw_activateRunsWaterfallLayout()
            contentView.mcvw_runsWaterfallLayout.delegate = self
        }
        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcvc_load(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header
        cv.mj_footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.mcvc_load(kind: .loadMore)
        }
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        guard mcvc_projectSegment != nil else { return }
        mcvc_load(kind: .initial)
    }
}

extension MCCProjectsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcvw_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcvc_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcvc_onListDidAppear?()
    }
}


extension MCCProjectsListPageController {

    public func mcvc_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcvc_pagingScrollCallback?(scrollView)
    }

    private var mcvc_isLikes: Bool {
        (mcvc_projectSegment?.ref ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "likes"
    }

    private func mcvc_canFetch(_ kind: MCCProjectListLoadKind) -> Bool {
        let s = mcvc_listState
        let lk = mcvc_isLikes
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


private extension MCCProjectsListPageController {

    func mcvc_load(kind: MCCProjectListLoadKind) {
        guard mcvc_projectSegment != nil, mcvc_canFetch(kind) else { return }
        if mcvc_isLikes {
            mcvc_loadLikes(kind)
        } else {
            mcvc_loadRuns(kind)
        }
    }

    func mcvc_beginLoadMore() {
        mcvc_listState.isLoadingMore = true
        mcvc_applyListUI()
    }

    func mcvc_endLoadMore() {
        mcvc_listState.isLoadingMore = false
        mcvc_applyListUI()
    }

    func mcvc_loadRuns(_ kind: MCCProjectListLoadKind) {
        if kind == .loadMore {
            mcvc_beginLoadMore()
            var request = MCSRunListRequest()
            request.itemsPerPage = MCCProjectsListLayout.pageSize
            let lastId = mcvc_listState.runItems.last?.runId
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !lastId.isEmpty {
                request.resumeAfterId = lastId
            }
            MCCRunAPIManager.shared.inventory(with: request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] _ in self?.mcvc_endLoadMore() },
                    receiveValue: { [weak self] page in
                        guard let self else { return }
                        self.mcvc_listState.runItems.append(contentsOf: page.items)
                        self.mcvc_listState.hasMore = page.items.count >= MCCProjectsListLayout.pageSize
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
                self.mcvc_listState.runLoadState = state
                if let m = state.model, !state.isLoading, state.error == nil {
                    self.mcvc_listState.runItems = m.items
                    self.mcvc_listState.hasMore = m.items.count >= MCCProjectsListLayout.pageSize
                }
                self.mcvc_applyListUI()
            }
            .store(in: &cancellables)
    }

    func mcvc_loadLikes(_ kind: MCCProjectListLoadKind) {
        let pageSz = MCCProjectsListLayout.pageSize

        if kind == .loadMore {
            mcvc_beginLoadMore()
            var request = MCSFeedLikeListRequest()
            request.itemsPerPage = pageSz
            request.pageIndex = mcvc_listState.favorNextPageIndex
            MCCFeedAPIManager.shared.favorInventory(with: request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] _ in self?.mcvc_endLoadMore() },
                    receiveValue: { [weak self] page in
                        guard let self else { return }
                        self.mcvc_listState.feedItems.append(contentsOf: page.items)
                        self.mcvc_listState.hasMore = page.items.count >= pageSz
                        self.mcvc_listState.favorNextPageIndex += 1
                    }
                )
                .store(in: &cancellables)
            return
        }

        if kind == .pullToRefresh || kind == .initial {
            mcvc_listState.favorNextPageIndex = 1
            mcvc_listState.feedItems = []
            mcvc_listState.hasMore = false
        }

        var request = MCSFeedLikeListRequest()
        request.itemsPerPage = pageSz
        request.pageIndex = 1
        MCCFeedAPIManager.shared.favorInventory(with: request)
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.mcvc_listState.feedLoadState = state
                if let m = state.model, !state.isLoading, state.error == nil {
                    self.mcvc_listState.feedItems = m.items
                    let full = m.items.count >= pageSz
                    self.mcvc_listState.hasMore = full
                    self.mcvc_listState.favorNextPageIndex = full ? 2 : 1
                }
                self.mcvc_applyListUI()
            }
            .store(in: &cancellables)
    }

    func mcvc_applyListUI() {
        let st = mcvc_listState
        let likes = mcvc_isLikes
        let count = st.itemCount(isLikes: likes)
        let loading = st.primaryIsLoading(isLikes: likes)
        let cv = contentView.mcvw_collectionView

        contentView.mcvw_setListSkeletonVisible(loading && count == 0)

        if loading && count == 0 {
            cv.mj_footer?.isHidden = true
        } else if !loading {
            cv.mj_header?.endRefreshing()
            mcvc_syncFooter(cv, itemCount: count, hasMore: st.hasMore, loadingMore: st.isLoadingMore)
        }
        cv.isHidden = false
        cv.reloadData()
    }

    func mcvc_syncFooter(_ cv: UICollectionView, itemCount: Int, hasMore: Bool, loadingMore: Bool) {
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


extension MCCProjectsListPageController: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_isLikes ? mcvc_listState.feedItems.count : mcvc_listState.runItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if mcvc_isLikes {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId, for: indexPath
            ) as! MCCShotsListItemCell
            if let feed = mcvc_listState.feedItems[safe: indexPath.item] {
                mcvc_styleLikesCell(cell, item: feed, collectionView: collectionView)
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId, for: indexPath
        ) as! MCCProjectsRunCell
        if let run = mcvc_listState.runItems[safe: indexPath.item] {
            cell.mcvw_apply(run: run)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if mcvc_isLikes, let feed = mcvc_listState.feedItems[safe: indexPath.item] {
            let vc = MCCFeedDetailController()
            vc.mcvc_feedItem = feed
            if let cell = collectionView.cellForItem(at: indexPath) as? MCCShotsListItemCell {
                vc.mcvc_webpHandoff = cell.mcvw_captureWebpPlaybackHandoff()
            }
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        guard let run = mcvc_listState.runItems[safe: indexPath.item] else { return }
        let title = run.runId.isEmpty ? "Project" : run.runId
        let kind: MCCCreationResultKind = indexPath.item % 2 == 0 ? .successImage : .successVideo(totalDuration: 15)
        let vc = MCCCreationResultController(navigationTitle: title, kind: kind, workRef: run.runId)
        navigationController?.pushViewController(vc, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard mcvc_isLikes,
              let cell = cell as? MCCShotsListItemCell,
              let item = mcvc_listState.feedItems[safe: indexPath.item] else { return }
        let thumbPx = mcvc_likesThumbnailPixelSize(forCollectionWidth: collectionView.bounds.width)
        cell.mcvw_applyWebpAnimated(webpUrl: item.videoAsset.webpImageUrl, thumbnailPixelSize: thumbPx)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard mcvc_isLikes else { return }
        (cell as? MCCShotsListItemCell)?.mcvw_clearWebpAnimated()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcvc_forwardPagingScroll(scrollView)
    }
}

extension MCCProjectsListPageController: UICollectionViewDataSourcePrefetching {

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard mcvc_isLikes else { return }
        let items = mcvc_listState.feedItems
        let cvW = collectionView.bounds.width
        let cvWidth = cvW > 0 ? cvW : view.bounds.width
        for indexPath in indexPaths {
            guard let item = items[safe: indexPath.item] else { continue }
            let s = item.videoAsset.posterImageUrl
            guard !s.isEmpty, let u = URL(string: s) else { continue }
            let thumbPx = mcvc_likesThumbnailPixelSize(forCollectionWidth: cvWidth)
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
        if mcvc_isLikes {
            guard let item = mcvc_listState.feedItems[safe: indexPath.item] else { return 1 }
            return mcvc_heightForLikesItem(item, itemWidth: itemWidth)
        }
        guard mcvc_listState.runItems.indices.contains(indexPath.item) else { return 1 }
        return itemWidth * 160 / 120
    }
}

private extension MCCProjectsListPageController {

    func mcvc_likesThumbnailPixelSize(forCollectionWidth width: CGFloat) -> CGSize {
        let colW = contentView.mcvw_likesWaterfallColumnWidth(collectionWidth: width)
        return MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: colW)
    }

    func mcvc_styleLikesCell(_ cell: MCCShotsListItemCell, item: MCSFeedItem, collectionView: UICollectionView) {
        cell.mcvw_imageContainer.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        let a = item.videoAsset
        cell.mcvw_setImageHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        let thumbPx = mcvc_likesThumbnailPixelSize(forCollectionWidth: collectionView.bounds.width)
        cell.mcvw_applyPosterOnly(posterUrl: a.posterImageUrl, thumbnailPixelSize: thumbPx)
        let displaySeconds = item.tenSecondMode ? 10 : 5
        cell.mcvw_durationLabel.text = Self.mcvc_formatVideoDurationLabel(seconds: displaySeconds)
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

    func mcvc_heightForLikesItem(_ item: MCSFeedItem, itemWidth: CGFloat) -> CGFloat {
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

    static func mcvc_formatVideoDurationLabel(seconds: Int) -> String {
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


private extension MCCProjectsRunCell {

    func mcvw_apply(run: MCSRunItem) {
        mcvw_imageContainer.backgroundColor = UIColor(hex: Self.mcvw_hex(from: run.runId)) ?? .darkGray
        mcvw_thumbView.sd_cancelCurrentImageLoad()
        mcvw_thumbView.image = nil
    }

    static func mcvw_hex(from id: String) -> String {
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


public struct MCCProjectSegment: Equatable {
    public var ref: String
    public var title: String

    public init(ref: String, title: String) {
        self.ref = ref
        self.title = title
    }
}
