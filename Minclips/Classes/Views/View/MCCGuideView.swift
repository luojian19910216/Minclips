//
//  MCCGuideView.swift
//

import UIKit
import Common
import Combine
import CombineCocoa
import SnapKit

public final class MCCGuideView: MCCBaseView {
        
    public var models: [MCSGuide] = [] {
        didSet {
            var snapshot = NSDiffableDataSourceSnapshot<MCESection, MCSGuide>()
            snapshot.appendSections([.main])
            snapshot.appendItems(models, toSection: .main)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
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
        return item
    }()
    
    public lazy var dataSource: UICollectionViewDiffableDataSource<MCESection, MCSGuide> = {
        let guideCellRegistration = UICollectionView.CellRegistration<MCCGuideCell, MCSGuide> { [weak self] cell, indexPath, model in
            cell.titleLab.text = model.title
            cell.detailLab.text = model.detail
            cell.handleBtn.setTitle(model.handleBtnTitle, for: .normal)
            cell.handleBtn.controlEventPublisher(for: .touchUpInside)
                .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
                .sink { _ in
                    self?.onHandleBtnTap(model: model)
                }
                .store(in: &cell.cancellables)
        }
        let dataSource: UICollectionViewDiffableDataSource<MCESection, MCSGuide> = .init(collectionView: collectionView) { [weak self] collectionView, indexPath, model in
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
    
    public func onHandleBtnTap(model: MCSGuide) {
        guard let index = models.firstIndex(of: model) else { return }
        if index < models.count - 1 {
            let offsetX = MCCScreenSize.width * CGFloat(index + 1)
            collectionView.setContentOffset(.init(x: offsetX, y: 0), animated: true)
        } else {
            MCCAppConfig.shared.guideFlag = true
        }
    }
    
}

public final class MCCGuideCell: MCCBaseCollectionViewCell {
    
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
    }
    
}
