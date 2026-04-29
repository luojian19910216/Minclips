import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import SDWebImage

public class MCCProjectsController: MCCViewController<MCCProjectsView, MCCEmptyViewModel> {

    private static let mcvc_fallbackProjectSegments: [MCCProjectSegment] = [
        MCCProjectSegment(ref: "clips", title: "Clips"),
        MCCProjectSegment(ref: "character", title: "Character"),
        MCCProjectSegment(ref: "likes", title: "Likes"),
    ]

    private var mcvc_tagsLoadState: MCSLoadState<[MCCProjectSegment]> = MCSLoadState()

    private var mcvc_selectedTagIndex: Int = 0

    private var mcvc_segmentItems: [MCCProjectSegment] { mcvc_tagsLoadState.model ?? [] }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        self.tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Projects")
        
        self.tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_nav_setting")?.withRenderingMode(.alwaysTemplate),
            target: self,
            action: #selector(mcvc_onSettingsTapped)
        )
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.mcvw_setupPagingView(delegate: self)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")!
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
        mcvc_requestProjectTabTitles()
    }

    @objc
    private func mcvc_onSettingsTapped() {
        let vc = MCCSettingsController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private static func mcvc_fetchProjectTabTitlesSimulated() -> AnyPublisher<[MCCProjectSegment], Never> {
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

    private func mcvc_requestProjectTabTitles() {
        mcvc_tagsLoadState = MCSLoadState(isLoading: true, error: nil, model: Self.mcvc_fallbackProjectSegments)
        mcvc_syncTagChrome()
        mcvc_reloadPagingForTags()
        Self.mcvc_fetchProjectTabTitlesSimulated()
            .map { segs in MCSLoadState(isLoading: false, error: nil, model: segs) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                self.mcvc_tagsLoadState = s
                self.mcvc_syncTagChrome()
                self.mcvc_reloadPagingForTags()
            }
            .store(in: &cancellables)
    }

    private func mcvc_syncTagChrome() {
        contentView.mcvw_setPagingHidden(mcvc_segmentItems.isEmpty)
        contentView.mcvw_tagCollection.reloadData()
        let idx = min(mcvc_selectedTagIndex, max(0, mcvc_segmentItems.count - 1))
        if mcvc_segmentItems.indices.contains(idx) {
            contentView.mcvw_scrollTagToIndex(idx, animated: false)
        }
    }

    private func mcvc_reloadPagingForTags() {
        let segs = mcvc_segmentItems

        let idx: Int
        if segs.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, mcvc_selectedTagIndex), segs.count - 1)
        }
        mcvc_selectedTagIndex = idx
        contentView.mcvw_applyPagingTagReload(selectedIndex: idx, hasTags: !segs.isEmpty)
        if !segs.isEmpty {
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
        guard index >= 0, index < mcvc_segmentItems.count else { return }
        if mcvc_selectedTagIndex != index {
            mcvc_selectedTagIndex = index
        }
        contentView.mcvw_tagCollection.reloadData()
        contentView.mcvw_scrollTagToIndex(index, animated: true)
    }

    private func mcvc_gotoPage(at index: Int, animated: Bool) {
        guard index >= 0, index < mcvc_segmentItems.count else { return }
        let old = mcvc_selectedTagIndex
        if index == old, animated {
            contentView.mcvw_scrollTagToIndex(index, animated: true)
            return
        }
        if index == old { return }
        mcvc_selectedTagIndex = index
        contentView.mcvw_tagCollection.reloadData()
        if let c = contentView.mcvw_pagingListContainer, index < mcvc_segmentItems.count {
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MCCProjectsTagCell.mcvw_reuseId, for: indexPath) as! MCCProjectsTagCell
        if let it = mcvc_segmentItems[safe: indexPath.item] {
            let selected = indexPath.item == mcvc_selectedTagIndex
            cell.mcvw_titleLabel.text = it.title
            cell.mcvw_titleLabel.font = .systemFont(ofSize: 16, weight: selected ? .semibold : .regular)
            cell.mcvw_titleLabel.textColor = selected ? UIColor(hex: "FFFFFF")! : UIColor(hex: "8E8E93")!
            cell.mcvw_iconView.isHidden = true
            cell.mcvw_iconView.sd_cancelCurrentImageLoad()
            cell.mcvw_iconView.image = nil
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
        contentView.mcvw_pinHeaderView
    }

    public func numberOfLists(in pagingView: JXPagingView) -> Int {
        mcvc_segmentItems.count
    }

    public func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? {
        guard mcvc_segmentItems.indices.contains(index) else { return nil }
        return mcvc_segmentItems[index].ref
    }

    public func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let seg = mcvc_segmentItems[index]

        let list = MCCProjectsListPageController()
        list.mcvc_projectSegment = seg
        list.mcvc_pageIndex = index
        list.mcvc_onListDidAppear = { [weak self] in
            self?.mcvc_pagingListDidShow(at: index)
        }
        return list
    }

}

extension MCCProjectsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_segmentItems.count
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
        guard let it = mcvc_segmentItems[safe: indexPath.item] else { return .zero }
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
