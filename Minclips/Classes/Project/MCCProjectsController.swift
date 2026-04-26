import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import SDWebImage

public class MCCProjectsController: MCCViewController<MCCProjectsView, MCCEmptyViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private var mcpj_tagsLoadState: MCSLoadState<[MCCProjectSegment]> = MCSLoadState()

    private var mcpj_selectedTagIndex: Int = 0

    private var mcpj_segmentItems: [MCCProjectSegment] { mcpj_tagsLoadState.model ?? [] }

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
            title: "Projects",
            textColor: .white
        )
        item.rightBarButtonItem = MCCRootTabNavChrome.settingsBarButtonItem(
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
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")!
        contentView.backgroundColor = view.backgroundColor
        contentView.mcpj_tagCollection.backgroundColor = .clear
        contentView.mcpj_pinHeaderView.backgroundColor = .clear
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

    private func mcpj_dequeueTagCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsTagCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsTagCell
        if let it = mcpj_segmentItems[safe: indexPath.item] {
            let selected = indexPath.item == mcpj_selectedTagIndex
            cell.mcsv_titleLabel.text = it.title
            cell.mcsv_titleLabel.font = .systemFont(
                ofSize: 16,
                weight: selected ? .semibold : .regular
            )
            cell.mcsv_titleLabel.textColor = selected ? UIColor(hex: "FFFFFF")! : UIColor(hex: "8E8E93")!
            cell.mcsv_iconView.isHidden = true
            cell.mcsv_iconView.sd_cancelCurrentImageLoad()
            cell.mcsv_iconView.image = nil
        }
        return cell
    }

}

extension MCCProjectsController: JXPagingViewDelegate {

    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 0 }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }

    public func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        Int(ceil(MCCScreenSize.statusBarHeight))
    }

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
        list.mcpj_onListDidAppear = { [weak self] in
            self?.mcpj_pagingListDidShow(at: index)
        }
        return list
    }

}

extension MCCProjectsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcpj_segmentItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        mcpj_dequeueTagCell(collectionView, indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mcpj_gotoPage(at: indexPath.item, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let it = mcpj_segmentItems[safe: indexPath.item] else { return .zero }
        let t = it.title
        let fs: CGFloat = 16
        let textW = (t as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: fs, weight: .medium)]
        ).width
        return CGSize(width: textW + 4, height: 32)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
