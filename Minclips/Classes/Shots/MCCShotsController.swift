import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data
import MJRefresh
import SDWebImage

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

public final class MCCShotsController: MCCViewController<MCCShotsView, MCCEmptyViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private var mcsv_tagsState = MCSLoadState<MCSList<MCSFeedLabelItem>>()

    private var mcsv_selectedTagIndex: Int = 0

    private var mcsv_listStateByRef: [String: MCCShotsListState] = [:]

    private var mcsv_listPageByRef: [String: MCCShotsListPageController] = [:]

    private var mcsv_listRefByCollectionObjectId: [ObjectIdentifier: String] = [:]

    private var mcsv_labelItems: [MCSFeedLabelItem] { mcsv_tagsState.model?.items ?? [] }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        let item = navigationItem
        title = nil
        item.title = nil
        item.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        item.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(
            title: "Shorts",
            textColor: .white
        )
        item.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.mcsv_setupPagingView(delegate: self)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")!
        contentView.backgroundColor = view.backgroundColor
        contentView.mcsv_tagCollection.backgroundColor = .clear
        contentView.mcsv_pinHeaderView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        contentView.mcsv_tagCollection.dataSource = self
        contentView.mcsv_tagCollection.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcsv_loadTags()
    }

    private func mcsv_loadTags() {
        mcsv_selectedTagIndex = 0
        MCCFeedAPIManager.shared.customLabels()
            .asLoadState()
            .sink { [weak self] s in
                guard let self = self else { return }
                self.mcsv_tagsState = s
                self.mcsv_syncTagChrome()
                self.mcsv_reloadPagingForTags()
            }
            .store(in: &cancellables)
    }

    private func mcsv_syncTagChrome() {
        contentView.mcsv_setPagingHidden(mcsv_labelItems.isEmpty)
        contentView.mcsv_tagCollection.reloadData()
        let idx = min(mcsv_selectedTagIndex, max(0, mcsv_labelItems.count - 1))
        if mcsv_labelItems.indices.contains(idx) {
            contentView.mcsv_scrollTagToIndex(idx, animated: false)
        }
    }

    private func mcsv_reloadPagingForTags() {
        let labelItems = mcsv_labelItems
        let idx: Int
        if labelItems.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, mcsv_selectedTagIndex), labelItems.count - 1)
        }
        mcsv_selectedTagIndex = idx
        contentView.mcsv_applyPagingTagReload(selectedIndex: idx, hasLabels: !labelItems.isEmpty)
        if !labelItems.isEmpty {
            mcsv_pagingScrollToIndexIfVisible(idx, animated: false)
        }
    }

    private func mcsv_pagingScrollToIndexIfVisible(_ index: Int, animated: Bool) {
        guard let c0 = contentView.mcsv_pagingListContainer, index >= 0 else { return }
        let apply: () -> Void = { [weak self] in
            guard let c = self?.contentView.mcsv_pagingListContainer, c.bounds.width > 0 else { return }
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

    private func mcsv_pagingListDidShow(at index: Int) {
        guard index >= 0, index < mcsv_labelItems.count else { return }
        if mcsv_selectedTagIndex != index {
            mcsv_selectedTagIndex = index
        }
        contentView.mcsv_tagCollection.reloadData()
        contentView.mcsv_scrollTagToIndex(index, animated: true)
    }

    private func mcsv_gotoPage(at index: Int, animated: Bool) {
        guard index >= 0, index < mcsv_labelItems.count else { return }
        let old = mcsv_selectedTagIndex
        if index == old, animated {
            contentView.mcsv_scrollTagToIndex(index, animated: true)
            return
        }
        if index == old { return }
        mcsv_selectedTagIndex = index
        contentView.mcsv_tagCollection.reloadData()
        if let c = contentView.mcsv_pagingListContainer, index < mcsv_labelItems.count {
            c.didClickSelectedItem(at: index)
        }
        if let c = contentView.mcsv_pagingListContainer, c.bounds.width > 0 {
            c.scrollView.setContentOffset(
                CGPoint(x: CGFloat(index) * c.bounds.width, y: 0),
                animated: animated
            )
        }
    }

    private func mcsv_loadList(_ refId: String, kind: MCCShotsListLoadKind) {
        var st = mcsv_listStateByRef[refId] ?? MCCShotsListState()
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
            mcsv_listStateByRef[refId] = st
            mcsv_applyListUI(refId: refId)
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
                        var s = self.mcsv_listStateByRef[refId] ?? MCCShotsListState()
                        s.isLoadingMore = false
                        self.mcsv_listStateByRef[refId] = s
                        self.mcsv_applyListUI(refId: refId)
                    },
                    receiveValue: { [weak self] list in
                        guard let self = self else { return }
                        var s = self.mcsv_listStateByRef[refId] ?? MCCShotsListState()
                        s.isLoadingMore = false
                        s.items += list.items
                        s.hasMore = list.items.count >= 20
                        self.mcsv_listStateByRef[refId] = s
                        self.mcsv_applyListUI(refId: refId)
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
                    var s = self.mcsv_listStateByRef[refId] ?? MCCShotsListState()
                    s.listState = state
                    if let m = state.model, !state.isLoading, state.error == nil {
                        var list = m.items
                        if list.isEmpty {
                            list = Self.mcsv_mockFeedItems()
                        }
                        s.items = list
                        s.hasMore = list.count >= 20
                    }
                    self.mcsv_listStateByRef[refId] = s
                    self.mcsv_applyListUI(refId: refId)
                }
                .store(in: &cancellables)
        }
    }

    private func mcsv_applyListUI(refId: String) {
        guard let list = mcsv_listPageByRef[refId] else { return }
        let st = mcsv_listStateByRef[refId] ?? MCCShotsListState()
        let items = st.items
        let listState = st.listState
        let isLoadingMore = st.isLoadingMore
        let hasMore = st.hasMore
        let cv = list.contentView.mcsv_collectionView
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

}

extension MCCShotsController: JXPagingViewDelegate {

    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 0 }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }

    public func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        Int(ceil(MCCScreenSize.statusBarHeight))
    }

    public func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        contentView.mcsv_pinHeaderView
    }

    public func numberOfLists(in pagingView: JXPagingView) -> Int {
        mcsv_labelItems.count
    }

    public func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? {
        guard mcsv_labelItems.indices.contains(index) else { return nil }
        return mcsv_labelItems[index].templateRef
    }

    public func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let labelItem = mcsv_labelItems[index]
        let list = MCCShotsListPageController()
        list.mcsv_labelItem = labelItem
        list.mcsv_index = index
        list.mcsv_listHost = self
        list.mcsv_onListDidAppear = { [weak self] in
            self?.mcsv_pagingListDidShow(at: index)
        }
        let ref = labelItem.templateRef
        mcsv_listPageByRef[ref] = list
        return list
    }

}

extension MCCShotsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === contentView.mcsv_tagCollection {
            return mcsv_labelItems.count
        }
        guard let ref = mcsv_listRefByCollectionObjectId[ObjectIdentifier(collectionView)] else { return 0 }
        return mcsv_listStateByRef[ref]?.items.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === contentView.mcsv_tagCollection {
            return mcsv_dequeueTagCell(collectionView, indexPath: indexPath)
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsListItemCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsListItemCell
        if let ref = mcsv_listRefByCollectionObjectId[ObjectIdentifier(collectionView)],
           let item = mcsv_listStateByRef[ref]?.items[safe: indexPath.item] {
            mcsv_styleListCell(cell, item: item)
        }
        return cell
    }

    private func mcsv_dequeueTagCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsTagCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsTagCell
        if let it = mcsv_labelItems[safe: indexPath.item] {
            let selected = indexPath.item == mcsv_selectedTagIndex
            let iconUrl = it.iconImageUrl.isEmpty ? nil : it.iconImageUrl
            cell.mcsv_titleLabel.text = it.title
            cell.mcsv_titleLabel.font = .systemFont(
                ofSize: 16,
                weight: selected ? .semibold : .regular
            )
            cell.mcsv_titleLabel.textColor = selected ? UIColor(hex: "FFFFFF")! : UIColor(hex: "8E8E93")!
            if let urlStr = iconUrl, let u = URL(string: urlStr) {
                cell.mcsv_iconView.isHidden = false
                cell.mcsv_iconView.sd_setImage(with: u, placeholderImage: nil)
            } else {
                cell.mcsv_iconView.isHidden = true
                cell.mcsv_iconView.sd_cancelCurrentImageLoad()
                cell.mcsv_iconView.image = nil
            }
        }
        return cell
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

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === contentView.mcsv_tagCollection else { return }
        mcsv_gotoPage(at: indexPath.item, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView === contentView.mcsv_tagCollection {
            guard let it = mcsv_labelItems[safe: indexPath.item] else { return .zero }
            let t = it.title
            let fs: CGFloat = 16
            let textW = (t as NSString).size(
                withAttributes: [.font: UIFont.systemFont(ofSize: fs, weight: .medium)]
            ).width
            let hasIcon = !it.iconImageUrl.isEmpty
            let extra: CGFloat = hasIcon ? 18 + 4 : 0
            return CGSize(width: textW + 4 + extra, height: 32)
        }
        let inset: CGFloat = 16
        let spacing: CGFloat = 8
        let w = (collectionView.bounds.width - inset * 2 - spacing) / 2
        if w <= 0 { return CGSize(width: 160, height: 220) }
        let thumbH = w * 4 / 3
        return CGSize(width: w, height: thumbH + 6 + 40)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView,
              let ref = mcsv_listRefByCollectionObjectId[ObjectIdentifier(cv)],
              let list = mcsv_listPageByRef[ref] else { return }
        list.mcsv_forwardPagingScroll(scrollView)
    }

}

extension MCCShotsController: MCCShotsListPageHost {

    public func mcsv_listPageDidLoad(_ list: MCCShotsListPageController) {
        list.view.backgroundColor = .clear
        let cv = list.contentView.mcsv_collectionView
        cv.backgroundColor = .clear
        let ref = list.mcsv_labelItem.templateRef
        mcsv_listPageByRef[ref] = list
        mcsv_listRefByCollectionObjectId[ObjectIdentifier(cv)] = ref
        cv.dataSource = self
        cv.delegate = self
        mcsv_loadList(ref, kind: .initial)
    }

    public func mcsv_listRequestRefresh(_ list: MCCShotsListPageController) {
        mcsv_loadList(list.mcsv_labelItem.templateRef, kind: .pullToRefresh)
    }

    public func mcsv_listRequestLoadMore(_ list: MCCShotsListPageController) {
        mcsv_loadList(list.mcsv_labelItem.templateRef, kind: .loadMore)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
