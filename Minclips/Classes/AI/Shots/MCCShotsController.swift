import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data
import SDWebImage

public final class MCCShotsController: MCCViewController<MCCShotsView, MCCEmptyViewModel> {

    private var mcvc_tagsState = MCSLoadState<MCSList<MCSFeedLabelItem>>()

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
        mcvc_selectedTagIndex = 0
        MCCFeedAPIManager.shared.customLabels()
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                self.mcvc_tagsState = s
                self.contentView.mcvw_setTabHomeSkeletonVisible(s.isLoading)
                self.mcvc_syncTagChrome()
                self.mcvc_reloadPagingForTags()
            }
            .store(in: &cancellables)
    }

    private func mcvc_syncTagChrome() {
        contentView.mcvw_setPagingHidden(mcvc_labelItems.isEmpty)
        contentView.mcvw_tagCollection.reloadData()
        let idx = min(mcvc_selectedTagIndex, max(0, mcvc_labelItems.count - 1))
        if mcvc_labelItems.indices.contains(idx) {
            contentView.mcvw_scrollTagToIndex(idx, animated: false)
        }
    }

    private func mcvc_reloadPagingForTags() {
        let labelItems = mcvc_labelItems

        let idx: Int
        if labelItems.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, mcvc_selectedTagIndex), labelItems.count - 1)
        }
        mcvc_selectedTagIndex = idx
        contentView.mcvw_applyPagingTagReload(selectedIndex: idx, hasLabels: !labelItems.isEmpty)
        if !labelItems.isEmpty {
            mcvc_pagingScrollToIndexIfVisible(idx, animated: false)
        }
    }

    private func mcvc_pagingScrollToIndexIfVisible(_ index: Int, animated: Bool) {
        guard let c0 = contentView.mcvw_pagingListContainer, index >= 0 else { return }
        let apply: () -> Void = { [weak self] in
            guard let c = self?.contentView.mcvw_pagingListContainer, c.bounds.width > 0 else { return }
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

    private func mcvc_pagingListDidShow(at index: Int) {
        guard index >= 0, index < mcvc_labelItems.count else { return }
        if mcvc_selectedTagIndex != index {
            mcvc_selectedTagIndex = index
        }
        contentView.mcvw_tagCollection.reloadData()
        contentView.mcvw_scrollTagToIndex(index, animated: true)
    }

    private func mcvc_gotoPage(at index: Int, animated: Bool) {
        guard index >= 0, index < mcvc_labelItems.count else { return }
        let old = mcvc_selectedTagIndex
        if index == old, animated {
            contentView.mcvw_scrollTagToIndex(index, animated: true)
            return
        }
        if index == old { return }
        mcvc_selectedTagIndex = index
        contentView.mcvw_tagCollection.reloadData()
        if let c = contentView.mcvw_pagingListContainer, index < mcvc_labelItems.count {
            c.didClickSelectedItem(at: index)
        }
        if let c = contentView.mcvw_pagingListContainer, c.bounds.width > 0 {
            c.scrollView.setContentOffset(
                CGPoint(x: CGFloat(index) * c.bounds.width, y: 0),
                animated: animated
            )
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
        Int(ceil(MCCScreenSize.statusBarHeight))
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
        mcvc_gotoPage(at: indexPath.item, animated: true)
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
        return CGSize(width: textW + 4 + extra, height: 32)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
