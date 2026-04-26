import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data
import SDWebImage

public final class MCCShotsController: MCCViewController<MCCShotsView, MCCEmptyViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private var mcsv_tagsState = MCSLoadState<MCSList<MCSFeedLabelItem>>()

    private var mcsv_selectedTagIndex: Int = 0

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
        list.mcsv_onListDidAppear = { [weak self] in
            self?.mcsv_pagingListDidShow(at: index)
        }
        return list
    }

}

extension MCCShotsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcsv_labelItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        mcsv_dequeueTagCell(collectionView, indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mcsv_gotoPage(at: indexPath.item, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
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

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
