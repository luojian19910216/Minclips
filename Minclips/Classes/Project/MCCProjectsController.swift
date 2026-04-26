import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data
import MJRefresh
import SDWebImage

private struct MCCProjectListState {

    var items: [MCSRunItem] = []

    var hasMore: Bool = false

    var listState: MCSLoadState<MCSList<MCSRunItem>> = MCSLoadState()

    var isLoadingMore: Bool = false

}

private enum MCCProjectListLoadKind: Sendable {
    case initial
    case pullToRefresh
    case loadMore
}

public class MCCProjectsController: MCCViewController<MCCProjectsView, MCCEmptyViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private var mcpj_tagsLoadState: MCSLoadState<[MCCProjectSegment]> = MCSLoadState()

    private var mcpj_selectedTagIndex: Int = 0

    private var mcpj_listStateByRef: [String: MCCProjectListState] = [:]

    private var mcpj_listPageByRef: [String: MCCProjectsListPageController] = [:]

    private var mcpj_listRefByCollectionObjectId: [ObjectIdentifier: String] = [:]

    private var mcpj_segmentItems: [MCCProjectSegment] { mcpj_tagsLoadState.model ?? [] }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }

    public override func mcvc_configureNav() {
        tabBarController?.navigationItem.title = "Projects"
        let gear = UIImage(systemName: "gearshape")
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: gear,
            style: .plain,
            target: self,
            action: #selector(mcpj_onSettingsTapped)
        )
    }

    @objc
    private func mcpj_onSettingsTapped() {
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.mcpj_setupPagingView(delegate: self)
        mcpj_applyRootStyle()
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        contentView.mcpj_tagCollection.dataSource = self
        contentView.mcpj_tagCollection.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcpj_requestProjectTabTitles()
    }

    private static func mcpj_fetchProjectTabTitlesSimulated() -> AnyPublisher<[MCCProjectSegment], Never> {
        Deferred {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    promise(
                        .success(
                            [
                                MCCProjectSegment(ref: "clips", title: "Clips"),
                                MCCProjectSegment(ref: "character", title: "Character"),
                                MCCProjectSegment(ref: "likes", title: "Likes")
                            ]
                        )
                    )
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func mcpj_requestProjectTabTitles() {
        mcpj_tagsLoadState = MCSLoadState(isLoading: true, error: nil, model: nil)
        Self.mcpj_fetchProjectTabTitlesSimulated()
            .map { segs in MCSLoadState(isLoading: false, error: nil, model: segs) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                self.mcpj_tagsLoadState = s
                self.mcpj_syncTagChrome()
                self.mcpj_reloadPagingForTags()
            }
            .store(in: &cancellables)
    }

    private func mcpj_applyRootStyle() {
        view.backgroundColor = UIColor(hex: "000000")
        contentView.backgroundColor = UIColor(hex: "000000")
        contentView.mcpj_tagCollection.backgroundColor = .clear
        contentView.mcpj_pinHeaderView.backgroundColor = .clear
    }

    private func mcpj_syncTagChrome() {
        contentView.mcpj_setPagingHidden(mcpj_segmentItems.isEmpty)
        contentView.mcpj_tagCollection.reloadData()
        let idx = min(mcpj_selectedTagIndex, max(0, mcpj_segmentItems.count - 1))
        if mcpj_segmentItems.indices.contains(idx) {
            contentView.mcpj_scrollTagToIndex(idx, animated: false)
        }
    }

    private func mcpj_reloadPagingForTags() {
        let segs = mcpj_segmentItems
        let idx: Int
        if segs.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, mcpj_selectedTagIndex), segs.count - 1)
        }
        mcpj_selectedTagIndex = idx
        contentView.mcpj_applyPagingTagReload(selectedIndex: idx, hasTags: !segs.isEmpty)
        if !segs.isEmpty {
            mcpj_pagingScrollToIndexIfVisible(idx, animated: false)
        }
    }

    private func mcpj_pagingScrollToIndexIfVisible(_ index: Int, animated: Bool) {
        guard let c0 = contentView.mcpj_pagingListContainer, index >= 0 else { return }
        let apply: () -> Void = { [weak self] in
            guard let c = self?.contentView.mcpj_pagingListContainer, c.bounds.width > 0 else { return }
            c.scrollView.setContentOffset(
                CGPoint(x: CGFloat(index) * c.bounds.width, y: 0),
                animated: animated
            )
        }
        apply()
        if c0.bounds.width <= 0 {
            DispatchQueue.main.async(execute: apply)
        }
    }

    private func mcpj_pagingListDidShow(at index: Int) {
        guard index >= 0, index < mcpj_segmentItems.count else { return }
        if mcpj_selectedTagIndex != index {
            mcpj_selectedTagIndex = index
        }
        contentView.mcpj_tagCollection.reloadData()
        contentView.mcpj_scrollTagToIndex(index, animated: true)
    }

    private func mcpj_gotoPage(at index: Int, animated: Bool) {
        guard index >= 0, index < mcpj_segmentItems.count else { return }
        let old = mcpj_selectedTagIndex
        if index == old, animated {
            contentView.mcpj_scrollTagToIndex(index, animated: true)
            return
        }
        if index == old { return }
        mcpj_selectedTagIndex = index
        contentView.mcpj_tagCollection.reloadData()
        if let c = contentView.mcpj_pagingListContainer, index < mcpj_segmentItems.count {
            c.didClickSelectedItem(at: index)
        }
        if let c = contentView.mcpj_pagingListContainer, c.bounds.width > 0 {
            c.scrollView.setContentOffset(
                CGPoint(x: CGFloat(index) * c.bounds.width, y: 0),
                animated: animated
            )
        }
    }

    private func mcpj_loadRunList(_ refId: String, kind: MCCProjectListLoadKind) {
        var st = mcpj_listStateByRef[refId] ?? MCCProjectListState()
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

        if kind == .loadMore {
            st.isLoadingMore = true
            mcpj_listStateByRef[refId] = st
            mcpj_applyListUI(refId: refId)
            var request = MCSRunListRequest()
            request.itemsPerPage = 20
            if let last = st.items.last, !last.runId.isEmpty {
                request.resumeAfterId = last.runId
            }
            MCCRunAPIManager.shared.inventory(with: request)
                .sink(
                    receiveCompletion: { [weak self] _ in
                        guard let self = self else { return }
                        var s = self.mcpj_listStateByRef[refId] ?? MCCProjectListState()
                        s.isLoadingMore = false
                        self.mcpj_listStateByRef[refId] = s
                        self.mcpj_applyListUI(refId: refId)
                    },
                    receiveValue: { [weak self] list in
                        guard let self = self else { return }
                        var s = self.mcpj_listStateByRef[refId] ?? MCCProjectListState()
                        s.isLoadingMore = false
                        s.items += list.items
                        s.hasMore = list.items.count >= 20
                        self.mcpj_listStateByRef[refId] = s
                        self.mcpj_applyListUI(refId: refId)
                    }
                )
                .store(in: &cancellables)
        } else {
            var request = MCSRunListRequest()
            request.itemsPerPage = 20
            MCCRunAPIManager.shared.inventory(with: request)
                .asLoadState()
                .sink { [weak self] state in
                    guard let self = self else { return }
                    var s = self.mcpj_listStateByRef[refId] ?? MCCProjectListState()
                    s.listState = state
                    if let m = state.model, !state.isLoading {
                        s.items = m.items
                        s.hasMore = m.items.count >= 20
                    }
                    self.mcpj_listStateByRef[refId] = s
                    self.mcpj_applyListUI(refId: refId)
                }
                .store(in: &cancellables)
        }
    }

    private func mcpj_applyListUI(refId: String) {
        guard let list = mcpj_listPageByRef[refId] else { return }
        let st = mcpj_listStateByRef[refId] ?? MCCProjectListState()
        let items = st.items
        let listState = st.listState
        let isLoadingMore = st.isLoadingMore
        let hasMore = st.hasMore
        let cv = list.contentView.mcpj_collectionView
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

    private static func mcpj_placeholderHex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars {
            h = h &* 31 &+ UInt(c.value)
        }
        return String(format: "%06X", h % 0xFFFFFF)
    }

    private static func mcpj_styleRunCell(_ cell: MCCProjectsRunCell, item: MCSRunItem) {
        let hex = mcpj_placeholderHex(from: item.runId)
        cell.mcpj_imageContainer.backgroundColor = UIColor(hex: hex) ?? .darkGray
        cell.mcpj_captionLabel.text = item.runId
        cell.mcpj_captionLabel.textColor = UIColor(white: 1, alpha: 0.55)
        cell.mcpj_thumbView.image = nil
    }

}

extension MCCProjectsController: JXPagingViewDelegate {

    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 0 }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }

    public func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int { 44 }

    public func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        contentView.mcpj_pinHeaderView
    }

    public func numberOfLists(in pagingView: JXPagingView) -> Int {
        mcpj_segmentItems.count
    }

    public func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? {
        guard mcpj_segmentItems.indices.contains(index) else { return nil }
        return mcpj_segmentItems[index].ref
    }

    public func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let seg = mcpj_segmentItems[index]
        let list = MCCProjectsListPageController()
        list.mcpj_segment = seg
        list.mcpj_index = index
        list.mcpj_listHost = self
        list.mcpj_onListDidAppear = { [weak self] in
            self?.mcpj_pagingListDidShow(at: index)
        }
        let ref = seg.ref
        mcpj_listPageByRef[ref] = list
        return list
    }

}

extension MCCProjectsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === contentView.mcpj_tagCollection {
            return mcpj_segmentItems.count
        }
        guard let ref = mcpj_listRefByCollectionObjectId[ObjectIdentifier(collectionView)] else { return 0 }
        return mcpj_listStateByRef[ref]?.items.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === contentView.mcpj_tagCollection {
            return mcpj_dequeueTagCell(collectionView, indexPath: indexPath)
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCProjectsRunCell.mcpj_reuseId, for: indexPath
        ) as! MCCProjectsRunCell
        if let ref = mcpj_listRefByCollectionObjectId[ObjectIdentifier(collectionView)],
           let item = mcpj_listStateByRef[ref]?.items[safe: indexPath.item] {
            Self.mcpj_styleRunCell(cell, item: item)
        }
        return cell
    }

    private func mcpj_dequeueTagCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsTagCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsTagCell
        if let it = mcpj_segmentItems[safe: indexPath.item] {
            let selected = indexPath.item == mcpj_selectedTagIndex
            cell.mcsv_titleLabel.text = it.title
            cell.mcsv_titleLabel.font = .systemFont(ofSize: 16, weight: selected ? .semibold : .regular)
            cell.mcsv_titleLabel.textColor = selected ? UIColor(hex: "FFFFFF") : UIColor(hex: "8E8E93")
            cell.mcsv_iconView.isHidden = true
            cell.mcsv_iconView.sd_cancelCurrentImageLoad()
            cell.mcsv_iconView.image = nil
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === contentView.mcpj_tagCollection else { return }
        mcpj_gotoPage(at: indexPath.item, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView === contentView.mcpj_tagCollection {
            guard let it = mcpj_segmentItems[safe: indexPath.item] else { return .zero }
            let t = it.title
            let textW = (t as NSString).size(
                withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
            ).width
            return CGSize(width: textW + 4, height: 32)
        }
        let inset: CGFloat = 16
        let spacing: CGFloat = 8
        let w = (collectionView.bounds.width - inset * 2 - spacing * 2) / 3
        if w <= 0 { return CGSize(width: 100, height: 160) }
        let thumbH = w * 4 / 3
        return CGSize(width: floor(w), height: thumbH + 4 + 14)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView,
              let ref = mcpj_listRefByCollectionObjectId[ObjectIdentifier(cv)],
              let list = mcpj_listPageByRef[ref] else { return }
        list.mcpj_forwardPagingScroll(scrollView)
    }

}

extension MCCProjectsController: MCCProjectsListPageHost {

    public func mcpj_listPageDidLoad(_ list: MCCProjectsListPageController) {
        list.view.backgroundColor = .clear
        let cv = list.contentView.mcpj_collectionView
        cv.backgroundColor = .clear
        let ref = list.mcpj_segment.ref
        mcpj_listPageByRef[ref] = list
        mcpj_listRefByCollectionObjectId[ObjectIdentifier(cv)] = ref
        cv.dataSource = self
        cv.delegate = self
        mcpj_loadRunList(ref, kind: .initial)
    }

    public func mcpj_listRequestRefresh(_ list: MCCProjectsListPageController) {
        mcpj_loadRunList(list.mcpj_segment.ref, kind: .pullToRefresh)
    }

    public func mcpj_listRequestLoadMore(_ list: MCCProjectsListPageController) {
        mcpj_loadRunList(list.mcpj_segment.ref, kind: .loadMore)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
