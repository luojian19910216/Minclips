//
//  MCCShotsListPageController.swift
//  单标签下双列列表：本页 MCCShotsListViewModel 拉取 feed；骨架、下拉刷新、上拉更多、空态。JXPaging 与 tab 由上层协调。
//

import UIKit
import SnapKit
import Common
import SkeletonView
import MJRefresh
import JXPagingView
import Combine
import Data
import Common

public final class MCCShotsListPageController: UIViewController {

    public let mcsv_labelItem: MCSFeedLabelItem
    public var mcsv_index: Int = 0
    public var mcsv_onListDidAppear: (() -> Void)?

    private let listViewModel = MCCShotsListViewModel()
    private var mcsv_pagingScrollCallback: ((UIScrollView) -> Void)?
    private var mcsv_uiCancellables = Set<AnyCancellable>()

    private var mcsv_items: [MCSFeedItem] = []

    public var mcsv_tagId: String { mcsv_labelItem.templateRef }

    public init(labelItem: MCSFeedLabelItem) {
        self.mcsv_labelItem = labelItem
        super.init(nibName: nil, bundle: nil)
        listViewModel.labelItem = labelItem
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private lazy var flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 10
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flow)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCShotsListItemCell.self, forCellWithReuseIdentifier: MCCShotsListItemCell.mcsv_reuseId)
        cv.dataSource = self
        cv.delegate = self
        cv.isSkeletonable = true
        return cv
    }()

    private let errorView = UIView()
    private let errorLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "8E8E93")
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    private lazy var retryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("重试", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.tintColor = .white
        b.addTarget(self, action: #selector(mcsv_tapRetry), for: .touchUpInside)
        return b
    }()

    private let emptyView = UIView()
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "暂无内容"
        l.textColor = UIColor(hex: "8E8E93")
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        view.addSubview(errorView)
        view.addSubview(emptyView)
        errorView.addSubview(errorLabel)
        errorView.addSubview(retryButton)
        emptyView.addSubview(emptyLabel)
        errorView.isHidden = true
        emptyView.isHidden = true
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        errorView.snp.makeConstraints { $0.center.equalToSuperview() }
        errorLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(12)
            make.centerX.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints { $0.center.equalToSuperview() }
        emptyLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = MJRefreshNormalHeader { [weak self] in
            self?.listViewModel.mcsv_load(kind: .pullToRefresh)
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        collectionView.mj_header = header

        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.listViewModel.mcsv_load(kind: .loadMore)
        }
        collectionView.mj_footer = footer

        mcsv_bindListViewModel()
        listViewModel.mcsv_load(kind: .initial)
    }

    private func mcsv_bindListViewModel() {
        Publishers.CombineLatest4(
            listViewModel.$items,
            listViewModel.$listState,
            listViewModel.$isLoadingMore,
            listViewModel.$hasMore
        )
        .sink { [weak self] items, listState, isLoadingMore, hasMore in
            self?.mcsv_applyListState(
                items: items,
                listState: listState,
                isLoadingMore: isLoadingMore,
                hasMore: hasMore
            )
        }
        .store(in: &mcsv_uiCancellables)
    }

    private func mcsv_applyListState(
        items: [MCSFeedItem],
        listState: MCSLoadState<MCSList<MCSFeedItem>>,
        isLoadingMore: Bool,
        hasMore: Bool
    ) {
        mcsv_items = items
        if !listState.isLoading {
            collectionView.mj_header?.endRefreshing()
        }

        let hasErr = listState.error != nil && items.isEmpty && !listState.isLoading
        let showSkeleton = items.isEmpty && listState.isLoading && listState.error == nil

        if showSkeleton {
            errorView.isHidden = true
            emptyView.isHidden = true
            collectionView.isHidden = false
            collectionView.mj_footer?.isHidden = true
            if !collectionView.isSkeletonActive {
                collectionView.showAnimatedGradientSkeleton()
            }
        } else {
            if collectionView.isSkeletonActive {
                collectionView.stopSkeletonAnimation()
                collectionView.hideSkeleton()
            }
            if hasErr, items.isEmpty {
                errorView.isHidden = false
                emptyView.isHidden = true
                collectionView.isHidden = true
                errorLabel.text = listState.error.map { err in
                    (err as LocalizedError).errorDescription ?? err.localizedDescription
                }
                collectionView.mj_footer?.isHidden = true
            } else if !hasErr, items.isEmpty, !listState.isLoading, !isLoadingMore {
                errorView.isHidden = true
                emptyView.isHidden = false
                collectionView.isHidden = true
                collectionView.mj_footer?.isHidden = true
            } else {
                errorView.isHidden = true
                emptyView.isHidden = true
                collectionView.isHidden = false
                if !listState.isLoading {
                    if items.isEmpty {
                        collectionView.mj_footer?.isHidden = true
                    } else {
                        collectionView.mj_footer?.isHidden = false
                        if !isLoadingMore {
                            if hasMore {
                                collectionView.mj_footer?.resetNoMoreData()
                                collectionView.mj_footer?.endRefreshing()
                            } else {
                                collectionView.mj_footer?.endRefreshingWithNoMoreData()
                            }
                        }
                    }
                }
                collectionView.reloadData()
            }
        }
    }

    @objc
    private func mcsv_tapRetry() {
        listViewModel.mcsv_load(kind: .pullToRefresh)
    }
}

extension MCCShotsListPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcsv_items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsListItemCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsListItemCell
        if let item = mcsv_items[safe: indexPath.item] {
            cell.mcsv_apply(item: item)
        }
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset: CGFloat = 16
        let spacing: CGFloat = 8
        let w = (collectionView.bounds.width - inset * 2 - spacing) / 2
        if w <= 0 { return CGSize(width: 160, height: 220) }
        let thumbH = w * 4 / 3
        return CGSize(width: w, height: thumbH + 6 + 40)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mcsv_pagingScrollCallback?(scrollView)
    }
}

extension MCCShotsListPageController: JXPagingViewListViewDelegate {

    public func listView() -> UIView { view }

    public func listScrollView() -> UIScrollView { collectionView }

    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        mcsv_pagingScrollCallback = callback
    }

    public func listDidAppear() {
        mcsv_onListDidAppear?()
    }
}

// MARK: - Cell

private final class MCCShotsListItemCell: MCCBaseCollectionViewCell {
    fileprivate static let mcsv_reuseId = "MCCShotsListItemCell"
    private let imageContainer = UIView()
    private let durationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = UIColor(white: 0, alpha: 0.45)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()
    private let proBadge = UIView()
    private let proIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "diamond.fill"))
        iv.tintColor = .systemYellow
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(hex: "FFFFFF")
        l.numberOfLines = 2
        return l
    }()
    public override func mcvw_setupUI() {
        contentView.addSubview(imageContainer)
        contentView.addSubview(titleLabel)
        imageContainer.addSubview(durationLabel)
        imageContainer.addSubview(proBadge)
        proBadge.addSubview(proIcon)
        imageContainer.layer.cornerRadius = 12
        imageContainer.clipsToBounds = true
        imageContainer.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        durationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(6)
        }
        proBadge.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(6)
            make.size.equalTo(24)
        }
        proBadge.backgroundColor = UIColor(white: 0, alpha: 0.4)
        proBadge.layer.cornerRadius = 12
        proBadge.clipsToBounds = true
        proBadge.isHidden = true
        proIcon.snp.makeConstraints { $0.center.equalToSuperview() }
    }
    fileprivate func mcsv_apply(item: MCSFeedItem) {
        let hex = Self.mcsv_placeholderHex(from: item.itemId)
        imageContainer.backgroundColor = UIColor(hex: hex) ?? .darkGray
        durationLabel.text = " 00:00 "
        proBadge.isHidden = true
        titleLabel.text = item.itemId
    }

    private static func mcsv_placeholderHex(from id: String) -> String {
        var h: UInt = 0
        for c in id.unicodeScalars {
            h = h &* 31 &+ UInt(c.value)
        }
        return String(format: "%06X", h % 0xFFFFFF)
    }
    public override func prepareForReuse() {
        super.prepareForReuse()
        proBadge.isHidden = true
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
