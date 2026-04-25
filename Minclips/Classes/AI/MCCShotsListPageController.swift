//
//  MCCShotsListPageController.swift
//  单标签下双列列表：骨架、下拉刷新、错误重试。不持有 ViewModel，由 MCCShotsController 注入状态。
//

import UIKit
import SnapKit
import Common
import SkeletonView
import MJRefresh

public final class MCCShotsListPageController: UIViewController {

    public let mcsv_tagId: String
    public var mcsv_index: Int = 0
    public var mcsv_onPullToRefresh: (() -> Void)?
    public var mcsv_onListRetry: (() -> Void)?

    private var mcsv_items: [MCCShotItem] = []

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

    public init(tagId: String) {
        self.mcsv_tagId = tagId
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        view.addSubview(errorView)
        errorView.addSubview(errorLabel)
        errorView.addSubview(retryButton)
        errorView.isHidden = true
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        errorView.snp.makeConstraints { $0.center.equalToSuperview() }
        errorLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(12)
            make.centerX.bottom.equalToSuperview()
        }
        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcsv_onPullToRefresh?()
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        collectionView.mj_header = header
    }

    /// 由 Controller 根据 ViewModel 变化调用。
    public func mcsv_applyListState(items: [MCCShotItem], isLoading: Bool, listError: String?) {
        mcsv_items = items
        if !isLoading {
            collectionView.mj_header?.endRefreshing()
        }
        let hasErr = listError != nil && !(listError?.isEmpty ?? true)
        let showSkeleton = items.isEmpty && isLoading && !hasErr
        if showSkeleton {
            errorView.isHidden = true
            collectionView.isHidden = false
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
                collectionView.isHidden = true
                errorLabel.text = listError
            } else {
                errorView.isHidden = true
                collectionView.isHidden = false
                collectionView.reloadData()
            }
        }
    }

    @objc
    private func mcsv_tapRetry() {
        mcsv_onListRetry?()
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
    fileprivate func mcsv_apply(item: MCCShotItem) {
        imageContainer.backgroundColor = UIColor(hex: item.mockThumbHex) ?? .darkGray
        durationLabel.text = " \(item.durationText) "
        proBadge.isHidden = !item.isPro
        titleLabel.text = item.title
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
