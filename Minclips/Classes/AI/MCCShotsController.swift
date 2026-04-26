//
//  MCCShotsController.swift
//

import UIKit
import SnapKit
import Common
import Combine
import FDFullscreenPopGesture
import JXPagingView
import Data

public final class MCCShotsController: MCCViewController<MCCShotsView, MCCShotsViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private var mcsv_pagingView: JXPagingView?

    public override func mcvc_bindService() {
        super.mcvc_bindService()
        mcsv_subscribe()
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        viewModel.mcsv_loadTags()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        mcsv_setupPaging()
        mcsv_wireViewInputs()
    }

    @objc
    private func mcsv_tapPro() {}

    private func mcsv_setupPaging() {
        let pv = JXPagingView(delegate: self, listContainerType: .scrollView)
        pv.allowsCacheList = true
        mcsv_pagingView = pv
        contentView.mcsv_hostPagingView(pv)
    }

    private func mcsv_subscribe() {
        Publishers.CombineLatest(
            viewModel.$tagsState,
            viewModel.$selectedTagIndex
        )
        .removeDuplicates { a, b in
            a.0.isLoading == b.0.isLoading
                && a.0.model?.items.map(\.templateRef) == b.0.model?.items.map(\.templateRef)
                && a.0.error?.localizedDescription == b.0.error?.localizedDescription
                && a.1 == b.1
        }
        .sink { [weak self] state, index in
            self?.mcsv_onTagsOrPhaseChange(tagsState: state, selectedIndex: index)
        }
        .store(in: &cancellables)

        viewModel.$selectedTagIndex
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.contentView.mcsv_scrollSelectedTagToCenter(animated: true)
            }
            .store(in: &cancellables)
    }

    private func mcsv_onTagsOrPhaseChange(tagsState: MCSLoadState<MCSList<MCSFeedLabelItem>>, selectedIndex: Int) {
        let labelItems = tagsState.model?.items ?? []
        let idx: Int
        if labelItems.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, selectedIndex), labelItems.count - 1)
        }
        contentView.mcsv_applyTagStrip(tagsState: tagsState, selectedIndex: idx)
        guard let pv = mcsv_pagingView else { return }
        if tagsState.model != nil, !labelItems.isEmpty, tagsState.error == nil {
            pv.defaultSelectedIndex = idx
            pv.reloadData()
            mcsv_pagingScrollToIndexIfVisible(idx, animated: false)
        } else {
            pv.reloadData()
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
        guard index >= 0, index < viewModel.labelItems.count else { return }
        if viewModel.selectedTagIndex != index {
            viewModel.mcsv_selectTag(at: index)
        }
        contentView.mcsv_scrollSelectedTagToCenter(animated: true)
    }

    private func mcsv_wireViewInputs() {
        let v = contentView
        v.mcsv_tagIndexTapped
            .sink { [weak self] index in
                self?.mcsv_gotoPage(at: index, animated: true)
            }
            .store(in: &cancellables)
        v.mcsv_tagsRetryTapped
            .sink { [weak self] in
                self?.viewModel.mcsv_loadTags()
            }
            .store(in: &cancellables)
    }

    private func mcsv_gotoPage(at index: Int, animated: Bool) {
        guard index >= 0, index < viewModel.labelItems.count else { return }
        let old = viewModel.selectedTagIndex
        if index == old, animated {
            contentView.mcsv_scrollSelectedTagToCenter(animated: true)
            return
        }
        if index == old { return }
        viewModel.mcsv_selectTag(at: index)
        if let c = contentView.mcsv_pagingListContainer, index < viewModel.labelItems.count {
            c.didClickSelectedItem(at: index)
        }
        if let c = contentView.mcsv_pagingListContainer, c.bounds.width > 0 {
            c.scrollView.setContentOffset(
                CGPoint(x: CGFloat(index) * c.bounds.width, y: 0),
                animated: animated
            )
        }
    }
}

// MARK: - JXPagingViewDelegate

extension MCCShotsController: JXPagingViewDelegate {

    public func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 0 }

    public func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }

    public func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int { 44 }

    public func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        contentView.mcsv_pinHeaderView
    }

    public func numberOfLists(in pagingView: JXPagingView) -> Int {
        if viewModel.tagsState.isLoading { return 0 }
        if viewModel.tagsState.error != nil { return 0 }
        return viewModel.labelItems.count
    }

    public func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? {
        guard viewModel.labelItems.indices.contains(index) else { return nil }
        return viewModel.labelItems[index].templateRef
    }

    public func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let labelItem = viewModel.labelItems[index]
        let list = MCCShotsListPageController(labelItem: labelItem)
        list.mcsv_index = index
        list.mcsv_onListDidAppear = { [weak self] in
            self?.mcsv_pagingListDidShow(at: index)
        }
        return list
    }
}
