//
//  MCCShotsController.swift
//  导航栏大标题 + PRO；UIPageViewController 与横滑标签联动；View 不持 ViewModel。
//

import UIKit
import SnapKit
import Common
import Combine
import FDFullscreenPopGesture

public final class MCCShotsController: MCCViewController<MCCShotsView, MCCShotsViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: [UIPageViewController.OptionsKey.interPageSpacing: 0]
    )
    private var listPages: [MCCShotsListPageController] = []
    private var mcsv_isProgrammaticPageChange = false

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
        mcsv_setupPageViewController()
        mcsv_wireViewInputs()
    }

    @objc
    private func mcsv_tapPro() {}

    private func mcsv_setupPageViewController() {
        addChild(pageViewController)
        contentView.mcsv_pageContainer.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageViewController.didMove(toParent: self)
        pageViewController.dataSource = self
        pageViewController.delegate = self
    }

    private func mcsv_subscribe() {
        Publishers.CombineLatest3(
            viewModel.$tags,
            viewModel.$tagsPhase,
            viewModel.$selectedTagIndex
        )
        .removeDuplicates { a, b in
            a.0 == b.0 && a.1 == b.1 && a.2 == b.2
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] tags, phase, index in
            self?.mcsv_onTagsOrPhaseChange(tags: tags, phase: phase, selectedIndex: index)
        }
        .store(in: &cancellables)

        Publishers.CombineLatest3(
            viewModel.$listByTagId,
            viewModel.$listLoadingTagIds,
            viewModel.$listErrorByTagId
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.mcsv_refreshAllListPages()
        }
        .store(in: &cancellables)

        viewModel.$selectedTagIndex
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.contentView.mcsv_scrollSelectedTagToCenter(animated: true)
            }
            .store(in: &cancellables)
    }

    private func mcsv_onTagsOrPhaseChange(tags: [MCCShotTag], phase: MCCShotsTagsPhase, selectedIndex: Int) {
        let titles = tags.map { $0.title }
        let idx: Int
        if titles.isEmpty {
            idx = 0
        } else {
            idx = min(max(0, selectedIndex), tags.count - 1)
        }
        contentView.mcsv_applyTagStrip(phase: phase, tagTitles: titles, selectedIndex: idx)
        if case .success = phase, !tags.isEmpty {
            mcsv_ensureListPagesIfNeeded()
        } else {
            mcsv_tearDownListPages()
        }
    }

    private func mcsv_ensureListPagesIfNeeded() {
        let tags = viewModel.tags
        let needsRebuild = listPages.count != tags.count
            || zip(listPages, tags).contains { $0.mcsv_tagId != $1.id }
        if needsRebuild {
            mcsv_tearDownListPages()
            listPages = tags.map { MCCShotsListPageController(tagId: $0.id) }
            for (i, p) in listPages.enumerated() {
                p.mcsv_index = i
                let tagId = p.mcsv_tagId
                p.mcsv_onPullToRefresh = { [weak self] in
                    self?.viewModel.mcsv_loadList(tagId: tagId, isUserRefresh: true)
                }
                p.mcsv_onListRetry = p.mcsv_onPullToRefresh
            }
        }
        pageViewController.dataSource = self
        if let first = listPages.first, !mcsv_isProgrammaticPageChange,
            needsRebuild || pageViewController.viewControllers?.isEmpty != false
        {
            mcsv_isProgrammaticPageChange = true
            pageViewController.setViewControllers([first], direction: .forward, animated: false) { [weak self] _ in
                self?.mcsv_isProgrammaticPageChange = false
            }
        }
        mcsv_refreshAllListPages()
    }

    private func mcsv_tearDownListPages() {
        listPages = []
        pageViewController.dataSource = nil
    }

    private func mcsv_refreshAllListPages() {
        for p in listPages {
            let id = p.mcsv_tagId
            let items = viewModel.listByTagId[id] ?? []
            let loading = viewModel.listLoadingTagIds.contains(id)
            let err = viewModel.listErrorByTagId[id]
            p.mcsv_applyListState(items: items, isLoading: loading, listError: err)
        }
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
        guard index >= 0, index < listPages.count else { return }
        let old = viewModel.selectedTagIndex
        if index == old, animated {
            contentView.mcsv_scrollSelectedTagToCenter(animated: true)
            return
        }
        if index == old { return }
        viewModel.mcsv_selectTag(at: index)
        let direction: UIPageViewController.NavigationDirection = index > old ? .forward : .reverse
        mcsv_isProgrammaticPageChange = true
        pageViewController.setViewControllers(
            [listPages[index]], direction: direction, animated: animated
        ) { [weak self] _ in
            self?.mcsv_isProgrammaticPageChange = false
        }
    }
}

// MARK: - UIPageViewControllerDataSource & Delegate

extension MCCShotsController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let cur = viewController as? MCCShotsListPageController,
            let i = listPages.firstIndex(where: { $0 === cur }),
            i > 0
        else { return nil }
        return listPages[i - 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let cur = viewController as? MCCShotsListPageController,
            let i = listPages.firstIndex(where: { $0 === cur }),
            i < listPages.count - 1
        else { return nil }
        return listPages[i + 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed, !mcsv_isProgrammaticPageChange,
            let current = pageViewController.viewControllers?.first as? MCCShotsListPageController,
            let idx = listPages.firstIndex(where: { $0 === current })
        else { return }
        if idx != viewModel.selectedTagIndex {
            viewModel.mcsv_selectTag(at: idx)
        }
    }
}
