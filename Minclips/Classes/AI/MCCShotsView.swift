//
//  MCCShotsView.swift
//  分类条作为 JXPaging 悬浮 Header；JXPagingView 由 Controller 创建并 mcsv_hostPagingView 嵌入。导航栏在 Controller 配置。
//

import UIKit
import SnapKit
import Common
import Combine
import JXPagingView
import Data
import SDWebImage

public final class MCCShotsView: MCCBaseView {

    // MARK: - Input

    private let tagIndexTappedSubject = PassthroughSubject<Int, Never>()
    private let tagsRetryTappedSubject = PassthroughSubject<Void, Never>()

    public var mcsv_tagIndexTapped: AnyPublisher<Int, Never> {
        tagIndexTappedSubject.eraseToAnyPublisher()
    }
    public var mcsv_tagsRetryTapped: AnyPublisher<Void, Never> {
        tagsRetryTappedSubject.eraseToAnyPublisher()
    }

    // MARK: - 展示

    private var mcsv_tagLoadState = MCSLoadState<MCSList<MCSFeedLabelItem>>()
    private var mcsv_labelItems: [MCSFeedLabelItem] = []
    private var mcsv_selectedIndex: Int = 0

    private let tagsLoading = UIActivityIndicatorView(style: .large)
    private let tagsErrorStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 8
        s.isHidden = true
        return s
    }()
    private let tagsErrorLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "8E8E93")
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    private lazy var tagsRetryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("重试", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.tintColor = .white
        b.addTarget(self, action: #selector(mcsv_tagsRetryAction), for: .touchUpInside)
        return b
    }()

    private lazy var tagLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 12
        l.minimumLineSpacing = 0
        return l
    }()

    private lazy var tagCollection: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: tagLayout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cv.register(MCCShotsTagCell.self, forCellWithReuseIdentifier: MCCShotsTagCell.mcsv_reuseId)
        return cv
    }()

    /// 给 `JXPagingView` 的 `viewForPinSectionHeader` 用；内部含横向标签。勿直接加进 MCCShotsView 层级，由 JXP 持有。
    public let mcsv_pinHeaderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.frame = CGRect(x: 0, y: 0, width: 0, height: 44)
        return v
    }()

    private var mcsv_pagingViewRef: JXPagingView?
    public var mcsv_pagingListContainer: JXPagingListContainerView? { mcsv_pagingViewRef?.listContainerView }

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "000000")
        mcsv_pinHeaderView.addSubview(tagCollection)
        tagCollection.snp.makeConstraints { $0.edges.equalToSuperview() }
        addSubview(tagsLoading)
        addSubview(tagsErrorStack)
        tagsErrorStack.addArrangedSubview(tagsErrorLabel)
        tagsErrorStack.addArrangedSubview(tagsRetryButton)
        tagsLoading.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(12) }
        tagsErrorStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8)
        }
        tagCollection.dataSource = self
        tagCollection.delegate = self
        mcsv_syncTagsVisibility()
    }

    public func mcsv_hostPagingView(_ pagingView: JXPagingView) {
        mcsv_pagingViewRef = pagingView
        pagingView.backgroundColor = .clear
        if pagingView.superview == nil {
            addSubview(pagingView)
        }
        pagingView.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        bringSubviewToFront(tagsLoading)
        bringSubviewToFront(tagsErrorStack)
    }

    public func mcsv_applyTagStrip(tagsState: MCSLoadState<MCSList<MCSFeedLabelItem>>, selectedIndex: Int) {
        mcsv_tagLoadState = tagsState
        mcsv_labelItems = tagsState.model?.items ?? []
        mcsv_selectedIndex = min(max(0, selectedIndex), max(0, mcsv_labelItems.count - 1))
        mcsv_syncTagsVisibility()
        tagCollection.reloadData()
        mcsv_scrollSelectedTagToCenter(animated: false)
    }

    public func mcsv_scrollSelectedTagToCenter(animated: Bool) {
        guard mcsv_labelItems.indices.contains(mcsv_selectedIndex) else { return }
        let p = IndexPath(item: mcsv_selectedIndex, section: 0)
        tagCollection.layoutIfNeeded()
        tagCollection.scrollToItem(at: p, at: .centeredHorizontally, animated: animated)
    }

    private func mcsv_syncTagsVisibility() {
        let s = mcsv_tagLoadState
        if s.isLoading {
            tagsLoading.isHidden = false
            tagsLoading.startAnimating()
            tagsErrorStack.isHidden = true
            mcsv_pagingViewRef?.isHidden = true
        } else if s.error != nil {
            tagsLoading.isHidden = true
            tagsLoading.stopAnimating()
            tagsErrorLabel.text = s.error.map { err in
                (err as LocalizedError).errorDescription ?? err.localizedDescription
            }
            tagsErrorStack.isHidden = false
            mcsv_pagingViewRef?.isHidden = true
        } else if s.model != nil {
            tagsLoading.isHidden = true
            tagsLoading.stopAnimating()
            tagsErrorStack.isHidden = true
            mcsv_pagingViewRef?.isHidden = mcsv_labelItems.isEmpty
        } else {
            tagsLoading.isHidden = true
            tagsLoading.stopAnimating()
            tagsErrorStack.isHidden = true
            mcsv_pagingViewRef?.isHidden = true
        }
    }

    @objc
    private func mcsv_tagsRetryAction() {
        tagsRetryTappedSubject.send()
    }
}

extension MCCShotsView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcsv_labelItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsTagCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsTagCell
        if let it = mcsv_labelItems[safe: indexPath.item] {
            let icon = it.iconImageUrl.isEmpty ? nil : it.iconImageUrl
            cell.mcsv_apply(title: it.title, iconURL: icon, selected: indexPath.item == mcsv_selectedIndex)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tagIndexTappedSubject.send(indexPath.item)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let it = mcsv_labelItems[safe: indexPath.item] else { return .zero }
        let t = it.title
        let textW = (t as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
        ).width
        let hasIcon = !it.iconImageUrl.isEmpty
        let extra: CGFloat = hasIcon ? 18 + 4 : 0
        return CGSize(width: textW + 4 + extra, height: 32)
    }
}

// MARK: - Tag cell

private final class MCCShotsTagCell: MCCBaseCollectionViewCell {
    fileprivate static let mcsv_reuseId = "MCCShotsTagCell"
    private let iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        v.layer.cornerRadius = 2
        v.clipsToBounds = true
        return v
    }()
    private let label = UILabel()
    public override func mcvw_setupUI() {
        contentView.addSubview(iconView)
        contentView.addSubview(label)
        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
    }
    fileprivate func mcsv_apply(title: String, iconURL: String?, selected: Bool) {
        let hasIcon = iconURL != nil && !(iconURL?.isEmpty ?? true)
        iconView.isHidden = !hasIcon
        if hasIcon, let s = iconURL, let u = URL(string: s) {
            iconView.sd_setImage(with: u, placeholderImage: nil)
        } else {
            iconView.sd_cancelCurrentImageLoad()
            iconView.image = nil
        }
        if hasIcon {
            label.snp.remakeConstraints { make in
                make.leading.equalTo(iconView.snp.trailing).offset(4)
                make.trailing.centerY.equalToSuperview()
            }
        } else {
            label.snp.remakeConstraints { make in
                make.leading.trailing.centerY.equalToSuperview()
            }
        }
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: selected ? .semibold : .regular)
        label.textColor = selected ? UIColor(hex: "FFFFFF") : UIColor(hex: "8E8E93")
    }
    public override func prepareForReuse() {
        super.prepareForReuse()
        iconView.sd_cancelCurrentImageLoad()
        iconView.image = nil
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
