import UIKit
import SnapKit
import MJRefresh
import JXPagingView
import Data

public protocol MCCShotsListPageHost: AnyObject {

    func mcsv_listPageDidLoad(_ list: MCCShotsListPageController)

    func mcsv_listRequestRefresh(_ list: MCCShotsListPageController)

    func mcsv_listRequestLoadMore(_ list: MCCShotsListPageController)

}

public final class MCCShotsListPageController: MCCViewController<MCCShotsListPageView, MCCEmptyViewModel> {

    public var mcsv_labelItem: MCSFeedLabelItem!

    public var mcsv_index: Int = 0

    public var mcsv_onListDidAppear: (() -> Void)?

    public weak var mcsv_listHost: MCCShotsListPageHost?

    private var mcsv_pagingScrollCallback: ((UIScrollView) -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        let cv = contentView.mcsv_collectionView
        let header = MJRefreshNormalHeader { [weak self] in
            guard let self = self else { return }
            self.mcsv_listHost?.mcsv_listRequestRefresh(self)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header

        let footer = MJRefreshAutoNormalFooter { [weak self] in
            guard let self = self else { return }
            self.mcsv_listHost?.mcsv_listRequestLoadMore(self)
        }
        cv.mj_footer = footer
        
        mcsv_listHost?.mcsv_listPageDidLoad(self)
    }

}

extension MCCShotsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcsv_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcsv_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcsv_onListDidAppear?()
    }

}

extension MCCShotsListPageController {

    public func mcsv_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcsv_pagingScrollCallback?(scrollView)
    }

}
