import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data
import SDWebImage

public final class MCCToolsController: MCCViewController<MCCToolsView, MCCEmptyViewModel> {

    private var mcvc_groups: [MCSCfToolboxGroup] = []

    private var mcvc_selectedGroupIndex: Int = 0

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        self.tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(
            title: "Studio",
            textColor: .white
        )

        self.tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.mcvw_setupPagingView(delegate: self)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "0F0F12")!
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
        mcvc_loadStudioToolbox()
    }

    private func mcvc_loadStudioToolbox() {
        mcvc_selectedGroupIndex = 0
        MCCCfAPIManager.shared.studioToolbox()
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                if let m = s.model, !s.isLoading {
                    self.mcvc_groups = m.items
                } else if s.error != nil {
                    self.mcvc_groups = []
                }
                self.mcvc_syncGroupChrome()
                self.mcvc_reloadPagingForGroups()
            }
            .store(in: &cancellables)
    }

    private func mcvc_syncGroupChrome() {
        contentView.mcvw_setPagingHidden(mcvc_groups.isEmpty)
        contentView.mcvw_tagCollection.reloadData()
        let idx = min(mcvc_selectedGroupIndex, max(0, mcvc_groups.count - 1))
        if mcvc_groups.indices.contains(idx) {
            contentView.mcvw_scrollTagToIndex(idx, animated: false)
        }
    }

    private func mcvc_reloadPagingForGroups() {
        let groups = mcvc_groups

        let idx: Int
        if groups.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, mcvc_selectedGroupIndex), groups.count - 1)
        }
        mcvc_selectedGroupIndex = idx
        contentView.mcvw_applyPagingTagReload(selectedIndex: idx, hasGroups: !groups.isEmpty)
        if !groups.isEmpty {
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
        guard index >= 0, index < mcvc_groups.count else { return }
        if mcvc_selectedGroupIndex != index {
            mcvc_selectedGroupIndex = index
        }
        contentView.mcvw_tagCollection.reloadData()
        contentView.mcvw_scrollTagToIndex(index, animated: true)
    }

    private func mcvc_gotoPage(at index: Int, animated: Bool) {
        guard index >= 0, index < mcvc_groups.count else { return }
        let old = mcvc_selectedGroupIndex
        if index == old, animated {
            contentView.mcvw_scrollTagToIndex(index, animated: true)
            return
        }
        if index == old { return }
        mcvc_selectedGroupIndex = index
        contentView.mcvw_tagCollection.reloadData()
        if let c = contentView.mcvw_pagingListContainer, index < mcvc_groups.count {
            c.didClickSelectedItem(at: index)
        }
        if let c = contentView.mcvw_pagingListContainer, c.bounds.width > 0 {
            c.scrollView.setContentOffset(
                CGPoint(x: CGFloat(index) * c.bounds.width, y: 0),
                animated: animated
            )
        }
    }

    private func mcvc_groupTitle(at index: Int) -> String {
        guard let g = mcvc_groups[safe: index] else { return "" }
        let t = g.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        return "Studio"
    }

    private func mcvc_groupTagIconURL(at index: Int) -> URL? {
        guard let g = mcvc_groups[safe: index], let first = g.item.first else { return nil }
        let candidates = [first.iconInactive, first.iconActive, first.iconContent]
        guard
            let s = candidates.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { return nil }
        return URL(string: s)
    }

    private func mcvc_dequeueTagCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsTagCell.mcvw_reuseId, for: indexPath
        ) as! MCCShotsTagCell
        if mcvc_groups.indices.contains(indexPath.item) {
            let selected = indexPath.item == mcvc_selectedGroupIndex
            let title = mcvc_groupTitle(at: indexPath.item)
            cell.mcvw_titleLabel.text = title
            cell.mcvw_titleLabel.font = .systemFont(
                ofSize: 16,
                weight: selected ? .semibold : .regular
            )
            cell.mcvw_titleLabel.textColor = selected ? UIColor(hex: "FFFFFF")! : UIColor(hex: "8E8E93")!
            if let u = mcvc_groupTagIconURL(at: indexPath.item) {
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

extension MCCToolsController: JXPagingViewDelegate {

    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 0 }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }

    public func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        Int(ceil(MCCScreenSize.statusBarHeight))
    }

    public func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        contentView.mcvw_pinHeaderView
    }

    public func numberOfLists(in pagingView: JXPagingView) -> Int {
        mcvc_groups.count
    }

    public func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? {
        guard mcvc_groups.indices.contains(index) else { return nil }
        let g = mcvc_groups[index]
        let key = g.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return "studio-\(index)-\(key)"
    }

    public func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let group = mcvc_groups[index]

        let list = MCCToolsListPageController()
        list.mcvc_group = group
        list.mcvc_index = index
        list.mcvc_onListDidAppear = { [weak self] in
            self?.mcvc_pagingListDidShow(at: index)
        }
        return list
    }

}

extension MCCToolsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_groups.count
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
        let t = mcvc_groupTitle(at: indexPath.item)

        let fs: CGFloat = 16

        let textW = (t as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: fs, weight: .medium)]
        ).width
        let hasIcon = mcvc_groupTagIconURL(at: indexPath.item) != nil

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
