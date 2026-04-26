import UIKit
import JXPagingView
import Common
import Data

public final class MCCToolsListPageController: MCCViewController<MCCToolsListPageView, MCCEmptyViewModel> {

    public var mcvc_group: MCSCfToolboxGroup!

    public var mcvc_index: Int = 0

    public var mcvc_onListDidAppear: (() -> Void)?

    private var mcvc_pagingScrollCallback: ((UIScrollView) -> Void)?

    private var mcvc_items: [MCSCfToolboxItem] { mcvc_group?.item ?? [] }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.mcvw_collectionView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mcvw_collectionView
        cv.dataSource = self
        cv.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        guard mcvc_group != nil else { return }
        contentView.mcvw_collectionView.reloadData()
    }

}

extension MCCToolsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcvw_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcvc_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcvc_onListDidAppear?()
    }

}

extension MCCToolsListPageController {

    public func mcvc_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcvc_pagingScrollCallback?(scrollView)
    }

}

extension MCCToolsListPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCToolTextCell.mcvw_id,
            for: indexPath
        ) as! MCCToolTextCell
        if let item = mcvc_items[safe: indexPath.item] {
            cell.mcvw_textLabel.text = item.code
            cell.mcvw_textLabel.textColor = UIColor.white
            cell.mcvw_textLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            cell.contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        }
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        mcvc_itemSize(in: collectionView)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcvc_forwardPagingScroll(scrollView)
    }

}

private extension MCCToolsListPageController {

    func mcvc_itemSize(in collectionView: UICollectionView) -> CGSize {
        guard let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 100, height: 120)
        }

        let inset = flow.sectionInset

        let spacing = flow.minimumInteritemSpacing

        let inner = collectionView.bounds.width - inset.left - inset.right - spacing

        let colW = max(0, floor(inner / 2))
        return CGSize(width: colW, height: 120)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
