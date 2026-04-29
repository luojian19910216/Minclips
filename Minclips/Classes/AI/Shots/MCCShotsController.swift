import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data
import SDWebImage

public final class MCCShotsController: MCCViewController<MCCShotsView, MCCEmptyViewModel> {

    private var mcvc_tagsState = MCSLoadState<MCSList<MCSFeedLabelItem>>()
    
    private var mcvc_tagsFetchCancellable: AnyCancellable?
    
    private var mcvc_tagsAutoRetriedOnce = false
    
    private var mcvc_selectedTagIndex: Int = 0

    /// `true` ≈ 已过「轮播顶完、标签贴导航」临界点；用滞回避免临界点闪动、也避免在 layout 里误读 offset。
    private var mcvc_navStickyOpaqueLatched = false

    /// 上次真正写进 `navigationBar` 的状态，减少反复 `mc_barStyle` 触发整链布局
    private var mcvc_lastAppliedOpaqueBar: Bool?

    private var mcvc_labelItems: [MCSFeedLabelItem] { mcvc_tagsState.model?.items ?? [] }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Shots")
        tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_nav_pro"),
            title: "PRO",
            target: self,
            action: #selector(mcvc_onProTapped)
        )
        mcvc_resyncNavigationBarWithPinHeaderAfterGeometryChange()
    }

    public override func mcvc_setupLocalization() {
        contentView.backgroundColor = view.backgroundColor
        contentView.mcvw_tagCollection.backgroundColor = .clear
        contentView.mcvw_pinHeaderView.backgroundColor = .clear
    }
    
    public override func mcvc_bind() {
        contentView.mcvw_tagCollection.dataSource = self
        contentView.mcvw_tagCollection.delegate = self
    }
    
    public override func mcvc_loadData() {
        mcvc_loadTags()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.mcvw_setupPagingView(delegate: self)
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        contentView.mcvw_syncPinSectionHeaderOffset(navSafeInsetTop: view.safeAreaInsets.top)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.mcvw_syncPinSectionHeaderOffset(navSafeInsetTop: view.safeAreaInsets.top)
    }
    
}

extension MCCShotsController: JXPagingViewDelegate {

    public func pagingView(_ pagingView: JXPagingView, mainTableViewDidScroll scrollView: UIScrollView) {
        mcvc_updateStickyNavigationChrome(pagingView: pagingView, scrollYOffset: scrollView.contentOffset.y)
    }


    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int {
        let w = max(1, view.bounds.width > 1 ? view.bounds.width : UIScreen.main.bounds.width)
        return Int(MCCShotsCarouselMetrics.headerHeight(forWidth: w))
    }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView {
        contentView.mcvw_carouselHeaderView
    }

    public func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        48
    }

    public func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        contentView.mcvw_pinHeaderView
    }

    public func numberOfLists(in pagingView: JXPagingView) -> Int {
        mcvc_labelItems.count
    }

    public func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? {
        guard mcvc_labelItems.indices.contains(index) else { return nil }
        return mcvc_labelItems[index].templateRef
    }

    public func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let labelItem = mcvc_labelItems[index]

        let list = MCCShotsListPageController()
        list.mcvc_labelItem = labelItem
        list.mcvc_index = index
        list.mcvc_onListDidAppear = { [weak self] in
            self?.mcvc_pagingListDidShow(at: index)
        }
        return list
    }

}

extension MCCShotsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_labelItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        mcvc_dequeueTagCell(collectionView, indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mcvc_focusTagAndList(at: indexPath.item, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let it = mcvc_labelItems[safe: indexPath.item] else { return .zero }
        let t = it.title

        let fs: CGFloat = 16
        let textW = ceil(
            (t as NSString).size(withAttributes: [
                .font: UIFont.systemFont(ofSize: fs, weight: .semibold),
            ]).width
        )
        let hasIcon = !it.iconImageUrl.isEmpty
        let extra: CGFloat = hasIcon ? 18 + 6 : 0
        return CGSize(width: textW + 8 + extra, height: 48)
    }

}

extension MCCShotsController {

    /// 与 Pod 内 `JXPagingView.mainTableViewMaxContentOffsetY()` 同一公式：**Int(header) − pin**（不能用裸 `CGFloat`/`ceil`，否则与主表错位）
    private func mcvc_mainTableStickyMaxContentOffsetY(for pagingView: JXPagingView) -> CGFloat {
        CGFloat(tableHeaderViewHeight(in: pagingView)) - CGFloat(pagingView.pinSectionHeaderVerticalOffset)
    }

    /// 主表滚动：只在 **`mainTableView`** 滚动回调里改导航；阈值与 Pod 完全一致 + 大范围滞回退出，避免 inset/offset 瞬抖误判
    private func mcvc_updateStickyNavigationChrome(pagingView: JXPagingView, scrollYOffset y: CGFloat) {
        guard !mcvc_labelItems.isEmpty else {
            mcvc_navStickyOpaqueLatched = false
            mcvc_lastAppliedOpaqueBar = nil
            mcvc_applyOpaqueNavigationBarIfNeeded(false)
            return
        }
        guard contentView.mcvw_homePagingView?.isHidden != true else {
            mcvc_navStickyOpaqueLatched = false
            mcvc_lastAppliedOpaqueBar = nil
            mcvc_applyOpaqueNavigationBarIfNeeded(false)
            return
        }
        let maxY = mcvc_mainTableStickyMaxContentOffsetY(for: pagingView)
        /// 与 JX 内部「顶到临界点」对齐；略宽容 1pt 浮点
        let opaqueEnter = maxY - CGFloat(1)
        /// 退回透明要等主表明显下降（轮播往回露出来），不能把「略低于 maxY」的抖动当成离开
        let opaqueLeaveBand: CGFloat = 88
        let opaqueLeaveBelow = max(0, maxY - opaqueLeaveBand)
        if mcvc_navStickyOpaqueLatched {
            if y < opaqueLeaveBelow { mcvc_navStickyOpaqueLatched = false }
        } else if y >= opaqueEnter {
            mcvc_navStickyOpaqueLatched = true
        }
        mcvc_applyOpaqueNavigationBarIfNeeded(mcvc_navStickyOpaqueLatched)
    }

    /// 安全区 / `pinSectionHeaderVerticalOffset` 变化后延后一帧，按 Pod 阈值重算；与滚动滞回共用同一公式
    private func mcvc_resyncNavigationBarWithPinHeaderAfterGeometryChange() {
        guard let pv = contentView.mcvw_homePagingView, !mcvc_labelItems.isEmpty else {
            mcvc_navStickyOpaqueLatched = false
            mcvc_lastAppliedOpaqueBar = nil
            mcvc_applyOpaqueNavigationBarIfNeeded(false)
            return
        }
        guard pv.isHidden == false else {
            mcvc_navStickyOpaqueLatched = false
            mcvc_lastAppliedOpaqueBar = nil
            mcvc_applyOpaqueNavigationBarIfNeeded(false)
            return
        }
        let y = pv.mainTableView.contentOffset.y
        let maxY = mcvc_mainTableStickyMaxContentOffsetY(for: pv)
        mcvc_navStickyOpaqueLatched = y >= maxY - CGFloat(1)
        mcvc_applyOpaqueNavigationBarIfNeeded(mcvc_navStickyOpaqueLatched)
    }

    private func mcvc_applyOpaqueNavigationBarIfNeeded(_ opaque: Bool) {
        guard let bar = navigationController?.navigationBar else { return }
        if mcvc_lastAppliedOpaqueBar == opaque { return }
        mcvc_lastAppliedOpaqueBar = opaque
        bar.mc_shadowHidden = true
        bar.mc_barStyle = opaque ? .opaqueDark : .transparentLight
    }

}

extension MCCShotsController {

    @objc public func mcvc_onProTapped() {
        let vc: MCCProController = .init()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func mcvc_tagsConsiderAutoRetry(after s: MCSLoadState<MCSList<MCSFeedLabelItem>>) {
        guard !s.isLoading, mcvc_labelItems.isEmpty, !mcvc_tagsAutoRetriedOnce else { return }
        mcvc_tagsAutoRetriedOnce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.mcvc_loadTags()
        }
    }

    private func mcvc_applyTagsAndPagingAfterLoad() {
        let s = mcvc_tagsState
        let labels = mcvc_labelItems

        if s.isLoading {
            contentView.mcvw_setTabHomeSkeletonVisible(true)
        } else if labels.isEmpty {
            contentView.mcvw_setTabHomeSkeletonVisible(false)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.contentView.mcvw_setTabHomeSkeletonVisible(false)
            }
        }

        contentView.mcvw_setPagingHidden(labels.isEmpty)
        let idx: Int
        if labels.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, mcvc_selectedTagIndex), labels.count - 1)
        }
        mcvc_selectedTagIndex = idx
        contentView.mcvw_tagCollection.reloadData()
        contentView.mcvw_applyPagingTagReload(selectedIndex: idx, hasLabels: !labels.isEmpty)
        if !labels.isEmpty {
            mcvc_tagsAutoRetriedOnce = false
        }
        guard !labels.isEmpty else {
            mcvc_navStickyOpaqueLatched = false
            mcvc_lastAppliedOpaqueBar = nil
            mcvc_applyOpaqueNavigationBarIfNeeded(false)
            return
        }
        contentView.mcvw_scrollTagToIndex(idx, animated: false)
        mcvc_scrollListContainerOnly(to: idx, animated: false)
    }

    private func mcvc_scrollListContainerOnly(to index: Int, animated: Bool) {
        guard let container = contentView.mcvw_pagingListContainer, index >= 0 else { return }
        let apply = { [weak self] in
            guard let c = self?.contentView.mcvw_pagingListContainer, c.bounds.width > 0 else { return }
            c.scrollView.setContentOffset(CGPoint(x: CGFloat(index) * c.bounds.width, y: 0), animated: animated)
        }
        apply()
        if container.bounds.width <= 0 {
            DispatchQueue.main.async(execute: apply)
        }
    }

    private func mcvc_pagingListDidShow(at index: Int) {
        guard mcvc_labelItems.indices.contains(index) else { return }
        mcvc_selectedTagIndex = index
        contentView.mcvw_tagCollection.reloadData()
        contentView.mcvw_scrollTagToIndex(index, animated: true)
    }

    private func mcvc_focusTagAndList(at index: Int, animated: Bool) {
        guard mcvc_labelItems.indices.contains(index) else { return }
        let wasSame = index == mcvc_selectedTagIndex
        mcvc_selectedTagIndex = index
        contentView.mcvw_tagCollection.reloadData()
        contentView.mcvw_scrollTagToIndex(index, animated: animated)
        if wasSame { return }
        if let container = contentView.mcvw_pagingListContainer {
            container.scrollView.isScrollEnabled = true
            container.didClickSelectedItem(at: index)
        }
        contentView.layoutIfNeeded()
        mcvc_scrollListContainerOnly(to: index, animated: animated)
        if contentView.mcvw_pagingListContainer?.bounds.width ?? 0 <= 0 {
            DispatchQueue.main.async { [weak self] in
                self?.mcvc_scrollListContainerOnly(to: index, animated: animated)
            }
        }
    }

    private func mcvc_dequeueTagCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MCCShotsTagCell.mcvw_reuseId, for: indexPath) as! MCCShotsTagCell
        if let it = mcvc_labelItems[safe: indexPath.item] {
            let selected = indexPath.item == mcvc_selectedTagIndex

            let iconUrl = it.iconImageUrl.isEmpty ? nil : it.iconImageUrl
            cell.mcvw_titleLabel.text = it.title
            cell.mcvw_titleLabel.font = .systemFont(ofSize: 16, weight: selected ? .semibold : .regular)
            cell.mcvw_titleLabel.textColor = selected ? UIColor.white : UIColor.white.withAlphaComponent(0.48)
            if let urlStr = iconUrl, let u = URL(string: urlStr) {
                cell.mcvw_iconView.isHidden = false
                cell.mcvw_iconView.sd_setImage(with: u, placeholderImage: nil)
            } else {
                cell.mcvw_iconView.isHidden = true
                cell.mcvw_iconView.sd_cancelCurrentImageLoad()
                cell.mcvw_iconView.image = nil
            }
        }
        return cell
    }

}

extension MCCShotsController {
    
    private func mcvc_loadTags() {
        mcvc_tagsFetchCancellable?.cancel()
        mcvc_selectedTagIndex = 0
        mcvc_tagsFetchCancellable = MCCFeedAPIManager.shared.customLabels()
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                self.mcvc_tagsState = s
                self.mcvc_applyTagsAndPagingAfterLoad()
                self.mcvc_tagsConsiderAutoRetry(after: s)
            }
    }
    
}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
