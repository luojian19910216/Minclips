import UIKit
import Common
import Combine
import SnapKit

public struct MCCGuideViewInput {
    
    public var models: AnyPublisher<[MCSGuide], Never>

    public init(models: AnyPublisher<[MCSGuide], Never>) {
        self.models = models
    }

}

public enum MCCGuideViewOutput: Equatable {
    
    case primaryTapped(index: Int, model: MCSGuide, isLastPage: Bool)
    
    case pageIndexChanged(index: Int)
    
}

public final class MCCGuideView: MCCBaseView {

    private var models: [MCSGuide] = []

    private var lastPrimaryAt: Date?

    private let outputSubject = PassthroughSubject<MCCGuideViewOutput, Never>()

    public var output: AnyPublisher<MCCGuideViewOutput, Never> {
        outputSubject.eraseToAnyPublisher()
    }

    public lazy var collectionView: UICollectionView = {
        let item: UICollectionView = .init(frame: .zero, collectionViewLayout: {
            let layout: UICollectionViewFlowLayout = .init()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.itemSize = MCCScreenSize.size
            return layout
        }())
        item.backgroundColor = .clear
        item.contentInset = .zero
        item.bounces = false
        item.isPagingEnabled = true
        item.showsHorizontalScrollIndicator = false
        item.delegate = self
        return item
    }()

    public lazy var dataSource: UICollectionViewDiffableDataSource<MCESection, MCSGuide> = {
        let guideCellRegistration = UICollectionView.CellRegistration<MCCGuideCell, MCSGuide> { cell, _, model in
            cell.titleLab.text = model.title
            cell.detailLab.text = model.detail
            cell.handleBtn.setTitle(model.handleBtnTitle, for: .normal)
            cell.onPrimary = { [weak self] in
                self?.handlePrimary(model: model)
            }
        }

        let dataSource: UICollectionViewDiffableDataSource<MCESection, MCSGuide> = .init(collectionView: collectionView) { collectionView, indexPath, model in
            return collectionView.dequeueConfiguredReusableCell(
                using: guideCellRegistration,
                for: indexPath,
                item: model
            )
        }
        return dataSource
    }()

    public override func mcvw_setupUI() {
        self.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func bindInput(_ input: MCCGuideViewInput) {
        input.models
            .receive(on: DispatchQueue.main)
            .sink { [weak self] models in
                self?.applyModels(models)
            }
            .store(in: &cancellables)
    }

}

extension MCCGuideView: UICollectionViewDelegate {
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        emitPageIfChanged()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        emitPageIfChanged()
    }

}

extension MCCGuideView {

    private func applyModels(_ models: [MCSGuide]) {
        self.models = models
        var snapshot = NSDiffableDataSourceSnapshot<MCESection, MCSGuide>()
        snapshot.appendSections([.main])
        snapshot.appendItems(models, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func handlePrimary(model: MCSGuide) {
        let now = Date()
        if let last = lastPrimaryAt, now.timeIntervalSince(last) < 1 {
            return
        }
        lastPrimaryAt = now
        guard let index = models.firstIndex(where: { $0.id == model.id }) else { return }
        let isLast = index == models.count - 1
        outputSubject.send(.primaryTapped(index: index, model: model, isLastPage: isLast))
        if !isLast {
            let offsetX = MCCScreenSize.width * CGFloat(index + 1)
            collectionView.setContentOffset(.init(x: offsetX, y: 0), animated: true)
        }
    }

    private func currentPageIndex() -> Int {
        let w = MCCScreenSize.width
        guard w > 0 else { return 0 }
        return Int(round(collectionView.contentOffset.x / w))
    }

    private func emitPageIfChanged() {
        let page = min(max(0, currentPageIndex()), max(0, models.count - 1))
        outputSubject.send(.pageIndexChanged(index: page))
    }

}

public final class MCCGuideCell: MCCBaseCollectionViewCell {

    public var onPrimary: (() -> Void)?

    public lazy var titleLab: UILabel = {
        let item: UILabel = .init()
        item.numberOfLines = 0
        item.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        item.textColor = .white
        item.textAlignment = .left
        return item
    }()

    public lazy var detailLab: UILabel = {
        let item: UILabel = .init()
        item.numberOfLines = 0
        item.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        item.textColor = .white
        item.textAlignment = .left
        return item
    }()

    public lazy var handleBtn: UIButton = {
        let item: UIButton = .init()
        item.backgroundColor = .red
        item.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .black)
        item.setTitleColor(.white, for: .normal)
        return item
    }()

    public override func mcvw_setupUI() {
        self.contentView.addSubview(self.titleLab)
        self.titleLab.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
        }

        self.contentView.addSubview(self.detailLab)
        self.detailLab.snp.makeConstraints { make in
            make.top.equalTo(self.titleLab.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        self.contentView.addSubview(self.handleBtn)
        self.handleBtn.snp.makeConstraints { make in
            make.top.equalTo(self.detailLab.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(MCCScreenSize.bottomSafeHeight + 16)
            make.height.equalTo(48)
        }
        self.handleBtn.addTarget(self, action: #selector(mccg_handleBtnTouchUp), for: .touchUpInside)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        onPrimary = nil
    }

    @objc
    private func mccg_handleBtnTouchUp() {
        onPrimary?()
    }

}
