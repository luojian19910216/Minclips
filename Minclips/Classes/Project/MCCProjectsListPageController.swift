import UIKit
import SnapKit
import MJRefresh
import JXPagingView
import Combine
import Common
import Data

private struct MCCProjectListState {

    var items: [MCSRunItem] = []

    var hasMore: Bool = false

    var listState: MCSLoadState<MCSList<MCSRunItem>> = MCSLoadState()

    var isLoadingMore: Bool = false

}

private enum MCCProjectListLoadKind: Sendable {
    case initial
    case pullToRefresh
    case loadMore
}

public final class MCCProjectsListPageController: MCCViewController<MCCProjectsListPageView, MCCEmptyViewModel> {

    public var mcpj_segment: MCCProjectSegment!

    public var mcpj_index: Int = 0

    public var mcpj_onListDidAppear: (() -> Void)?

    private var mcpj_pagingScrollCallback: ((UIScrollView) -> Void)?

    private var mcpj_listState = MCCProjectListState()

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = .clear
        contentView.mcvw_collectionView.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mcvw_collectionView
        cv.dataSource = self
        cv.delegate = self

        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcpj_loadRunList(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header

        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.mcpj_loadRunList(kind: .loadMore)
        }
        cv.mj_footer = footer
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        guard mcpj_segment != nil else { return }
        mcpj_loadRunList(kind: .initial)
    }

}

extension MCCProjectsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { contentView.mcvw_collectionView }

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

extension MCCProjectsListPageController {

    private func mcpj_loadRunList(kind: MCCProjectListLoadKind) {
        guard mcpj_segment != nil else { return }
        var st = mcpj_listState
        switch kind {
        case .initial:
            if !st.items.isEmpty { return }
            if st.listState.isLoading { return }
        case .pullToRefresh:
            if st.listState.isLoading { return }
        case .loadMore:
            if !st.hasMore { return }
            if st.listState.isLoading { return }
            if st.isLoadingMore { return }
        }

        if kind == .loadMore {
            st.isLoadingMore = true
            mcpj_listState = st
            mcpj_applyListUI()
            var request = MCSRunListRequest()
            request.itemsPerPage = 20
            if let last = st.items.last, !last.runId.isEmpty {
                request.resumeAfterId = last.runId
            }
            MCCRunAPIManager.shared.inventory(with: request)
                .sink(
                    receiveCompletion: { [weak self] _ in
                        guard let self = self else { return }
                        self.mcpj_listState.isLoadingMore = false
                        self.mcpj_applyListUI()
                    },
                    receiveValue: { [weak self] list in
                        guard let self = self else { return }
                        self.mcpj_listState.isLoadingMore = false
                        self.mcpj_listState.items += list.items
                        self.mcpj_listState.hasMore = list.items.count >= 20
                        self.mcpj_applyListUI()
                    }
                )
                .store(in: &cancellables)
        } else {
            var request = MCSRunListRequest()
            request.itemsPerPage = 20
            MCCRunAPIManager.shared.inventory(with: request)
                .asLoadState()
                .sink { [weak self] state in
                    guard let self = self else { return }
                    self.mcpj_listState.listState = state
                    if let m = state.model, !state.isLoading, state.error == nil {
                        var list = m.items
                        if list.isEmpty {
                            list = Self.mcpj_mockRunItems()
                        }
                        self.mcpj_listState.items = list
                        self.mcpj_listState.hasMore = list.count >= 20
                    }
                    self.mcpj_applyListUI()
                }
                .store(in: &cancellables)
        }
    }

    private func mcpj_applyListUI() {
        let st = mcpj_listState
        let items = st.items
        let listState = st.listState
        let isLoadingMore = st.isLoadingMore
        let hasMore = st.hasMore
        let cv = contentView.mcvw_collectionView
        if !listState.isLoading {
            cv.mj_header?.endRefreshing()
        }
        if !listState.isLoading {
            if items.isEmpty {
                cv.mj_footer?.isHidden = true
            } else {
                cv.mj_footer?.isHidden = false
                if !isLoadingMore {
                    if hasMore {
                        cv.mj_footer?.resetNoMoreData()
                        cv.mj_footer?.endRefreshing()
                    } else {
                        cv.mj_footer?.endRefreshingWithNoMoreData()
                    }
                }
            }
        }
        cv.isHidden = false
        cv.reloadData()
    }

    private static func mcpj_mockRunItems() -> [MCSRunItem] {
        (0..<10).map { i in
            var it = MCSRunItem()
            it.runId = "mock_run_\(i)"
            it.createTime = Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + i))
            return it
        }
    }

    private static func mcpj_placeholderHex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars {
            h = h &* 31 &+ UInt(c.value)
        }
        return String(format: "%06X", h % 0xFFFFFF)
    }

    private func mcpj_styleRunCell(_ cell: MCCProjectsRunCell, item: MCSRunItem) {
        let hex = Self.mcpj_placeholderHex(from: item.runId)
        cell.mcvw_imageContainer.backgroundColor = UIColor(hex: hex) ?? .darkGray
        cell.mcvw_captionLabel.text = item.runId
        cell.mcvw_captionLabel.textColor = UIColor(white: 1, alpha: 0.55)
        cell.mcvw_thumbView.image = nil
    }

}


extension MCCProjectsListPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcpj_listState.items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId, for: indexPath
        ) as! MCCProjectsRunCell
        if let item = mcpj_listState.items[safe: indexPath.item] {
            mcpj_styleRunCell(cell, item: item)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = mcpj_listState.items[safe: indexPath.item] else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        let title = item.runId.isEmpty ? "Project" : item.runId
        let kind: MCCCreationResultKind = indexPath.item % 2 == 0
            ? .successImage
            : .successVideo(totalDuration: 15)
        let vc = MCCCreationResultController(navigationTitle: title, kind: kind, workRef: item.runId)
        navigationController?.pushViewController(vc, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset: CGFloat = 16
        let spacing: CGFloat = 8
        let w = (collectionView.bounds.width - inset * 2 - spacing * 2) / 3
        if w <= 0 { return CGSize(width: 100, height: 160) }
        let thumbH = w * 4 / 3
        return CGSize(width: floor(w), height: thumbH + 4 + 14)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcpj_forwardPagingScroll(scrollView)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
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
