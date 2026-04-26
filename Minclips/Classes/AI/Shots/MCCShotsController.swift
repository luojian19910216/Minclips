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

    private var mcvc_labelItems: [MCSFeedLabelItem] { mcvc_tagsState.model?.items ?? [] }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        self.tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Shorts")
        
        self.tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
    }

    @objc public func mcvc_onProTapped() {
        let vc: MCCProController = .init()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.mcvw_setupPagingView(delegate: self)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()

        contentView.backgroundColor = view.backgroundColor
        contentView.mcvw_tagCollection.backgroundColor = .clear
        contentView.mcvw_pinHeaderView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        contentView.mcvw_tagCollection.dataSource = self
        contentView.mcvw_tagCollection.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcvc_loadTags()
    }

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
        guard !labels.isEmpty else { return }
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

extension MCCShotsController: JXPagingViewDelegate {

    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 0 }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }

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

        let textW = (t as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: fs, weight: .medium)]
        ).width
        let hasIcon = !it.iconImageUrl.isEmpty

        let extra: CGFloat = hasIcon ? 18 + 4 : 0
        return CGSize(width: textW + 4 + extra, height: 48)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
