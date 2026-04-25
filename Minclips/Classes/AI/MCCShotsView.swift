//
//  MCCShotsView.swift
//  横滑标签 + 列表区域容器；不持有 ViewModel。导航栏在 Controller 配置。
//

import UIKit
import SnapKit
import Common
import Combine

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

    private var mcsv_phase: MCCShotsTagsPhase = .idle
    private var mcsv_tagTitles: [String] = []
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

    /// 嵌入 UIPageViewController 的 `view`。
    public let mcsv_pageContainer: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.backgroundColor = .clear
        return v
    }()

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "000000")
        addSubview(tagsLoading)
        addSubview(tagsErrorStack)
        tagsErrorStack.addArrangedSubview(tagsErrorLabel)
        tagsErrorStack.addArrangedSubview(tagsRetryButton)
        addSubview(tagCollection)
        addSubview(mcsv_pageContainer)
        tagsLoading.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(12) }
        tagsErrorStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8)
        }
        tagCollection.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        mcsv_pageContainer.snp.makeConstraints { make in
            make.top.equalTo(tagCollection.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tagCollection.dataSource = self
        tagCollection.delegate = self
        mcsv_syncTagsVisibility()
    }

    public func mcsv_applyTagStrip(phase: MCCShotsTagsPhase, tagTitles: [String], selectedIndex: Int) {
        mcsv_phase = phase
        mcsv_tagTitles = tagTitles
        mcsv_selectedIndex = min(max(0, selectedIndex), max(0, tagTitles.count - 1))
        mcsv_syncTagsVisibility()
        tagCollection.reloadData()
        mcsv_scrollSelectedTagToCenter(animated: false)
    }

    public func mcsv_scrollSelectedTagToCenter(animated: Bool) {
        guard mcsv_tagTitles.indices.contains(mcsv_selectedIndex) else { return }
        let p = IndexPath(item: mcsv_selectedIndex, section: 0)
        tagCollection.layoutIfNeeded()
        tagCollection.scrollToItem(at: p, at: .centeredHorizontally, animated: animated)
    }

    private func mcsv_syncTagsVisibility() {
        switch mcsv_phase {
        case .idle:
            tagsLoading.isHidden = true
            tagsLoading.stopAnimating()
            tagsErrorStack.isHidden = true
            tagCollection.isHidden = true
            mcsv_pageContainer.isHidden = true
        case .loading:
            tagsLoading.isHidden = false
            tagsLoading.startAnimating()
            tagsErrorStack.isHidden = true
            tagCollection.isHidden = true
            mcsv_pageContainer.isHidden = true
        case .failure:
            tagsLoading.isHidden = true
            tagsLoading.stopAnimating()
            if case .failure(let msg) = mcsv_phase {
                tagsErrorLabel.text = msg
            }
            tagsErrorStack.isHidden = false
            tagCollection.isHidden = true
            mcsv_pageContainer.isHidden = true
        case .success:
            tagsLoading.isHidden = true
            tagsLoading.stopAnimating()
            tagsErrorStack.isHidden = true
            tagCollection.isHidden = mcsv_tagTitles.isEmpty
            mcsv_pageContainer.isHidden = mcsv_tagTitles.isEmpty
        }
    }

    @objc
    private func mcsv_tagsRetryAction() {
        tagsRetryTappedSubject.send()
    }
}

extension MCCShotsView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcsv_tagTitles.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsTagCell.mcsv_reuseId, for: indexPath
        ) as! MCCShotsTagCell
        if let t = mcsv_tagTitles[safe: indexPath.item] {
            cell.mcsv_apply(title: t, selected: indexPath.item == mcsv_selectedIndex)
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
        if let t = mcsv_tagTitles[safe: indexPath.item] {
            let w = (t as NSString).size(
                withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
            ).width
            return CGSize(width: w + 4, height: 32)
        }
        return .zero
    }
}

// MARK: - Tag cell

private final class MCCShotsTagCell: MCCBaseCollectionViewCell {
    fileprivate static let mcsv_reuseId = "MCCShotsTagCell"
    private let label = UILabel()
    public override func mcvw_setupUI() {
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    fileprivate func mcsv_apply(title: String, selected: Bool) {
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: selected ? .semibold : .regular)
        label.textColor = selected ? UIColor(hex: "FFFFFF") : UIColor(hex: "8E8E93")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
