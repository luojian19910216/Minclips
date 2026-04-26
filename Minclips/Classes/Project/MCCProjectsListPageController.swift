import UIKit
import SnapKit
import MJRefresh
import JXPagingView

public protocol MCCProjectsListPageHost: AnyObject {

    func mcpj_listPageDidLoad(_ list: MCCProjectsListPageController)

    func mcpj_listRequestRefresh(_ list: MCCProjectsListPageController)

    func mcpj_listRequestLoadMore(_ list: MCCProjectsListPageController)

}

public final class MCCProjectsListPageController: MCCViewController<MCCProjectsListPageView, MCCEmptyViewModel> {

    public var mcpj_segment: MCCProjectSegment!

    public var mcpj_index: Int = 0

    public var mcpj_onListDidAppear: (() -> Void)?

    public weak var mcpj_listHost: MCCProjectsListPageHost?

    private var mcpj_pagingScrollCallback: ((UIScrollView) -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        let cv = contentView.mcpj_collectionView
        let header = MJRefreshNormalHeader { [weak self] in
            guard let self = self else { return }
            self.mcpj_listHost?.mcpj_listRequestRefresh(self)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header

        let footer = MJRefreshAutoNormalFooter { [weak self] in
            guard let self = self else { return }
            self.mcpj_listHost?.mcpj_listRequestLoadMore(self)
        }
        cv.mj_footer = footer

        mcpj_listHost?.mcpj_listPageDidLoad(self)
    }

}

extension MCCProjectsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcpj_collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcpj_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcpj_onListDidAppear?()
    }

}

extension MCCProjectsListPageController {

    public func mcpj_forwardPagingScroll(_ scrollView: UIScrollView) {
        mcpj_pagingScrollCallback?(scrollView)
    }

}

public struct MCCProjectSegment: Equatable {

    public var ref: String

    public var title: String

    public init(ref: String, title: String) {
        self.ref = ref
        self.title = title
    }

}
