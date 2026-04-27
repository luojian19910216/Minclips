import UIKit
import Common
import Combine
import SnapKit
import SDWebImage

public struct MCCGuideViewInput {

    public var models: AnyPublisher<[MCSGuide], Never>

    public init(models: AnyPublisher<[MCSGuide], Never>) {
        self.models = models
    }

}

public enum MCCGuideViewOutput: Equatable {

    case primaryTapped(index: Int, model: MCSGuide, isLastPage: Bool)

    case pickPhotoTapped

}

public final class MCCGuideView: MCCBaseView {

    private var models: [MCSGuide] = []

    private var lastPrimaryAt: Date?

    private var lastPrimaryIndex: Int?

    private var castLeadPreviewImage: UIImage?

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
        item.backgroundColor = .black
        item.contentInset = .zero
        item.bounces = false
        item.isPagingEnabled = true
        item.showsHorizontalScrollIndicator = false
        return item
    }()

    private lazy var storyRegistration: UICollectionView.CellRegistration<MCCGuideStoryCell, MCSGuide> = {
        UICollectionView.CellRegistration<MCCGuideStoryCell, MCSGuide> { [weak self] cell, indexPath, model in
            cell.mcvw_apply(model: model)
            cell.onPrimary = { [weak self] in
                self?.handlePrimary(at: indexPath.item)
            }
        }
    }()

    private lazy var castRegistration: UICollectionView.CellRegistration<MCCGuideCastCell, MCSGuide> = {
        UICollectionView.CellRegistration<MCCGuideCastCell, MCSGuide> { [weak self] cell, indexPath, model in
            guard let self else { return }
            cell.mcvw_apply(model: model, previewImage: self.castLeadPreviewImage)
            cell.onPrimary = { [weak self] in
                self?.handlePrimary(at: indexPath.item)
            }
            cell.onPickPhoto = { [weak self] in
                self?.outputSubject.send(.pickPhotoTapped)
            }
        }
    }()

    public lazy var dataSource: UICollectionViewDiffableDataSource<MCESection, MCSGuide> = {
        UICollectionViewDiffableDataSource<MCESection, MCSGuide>(collectionView: collectionView) { [weak self] collectionView, indexPath, model in
            guard let self else {
                preconditionFailure("MCCGuideView deallocated while dequeuing a cell")
            }
            switch model {
            case .story:
                return collectionView.dequeueConfiguredReusableCell(using: self.storyRegistration, for: indexPath, item: model)
            case .cast:
                return collectionView.dequeueConfiguredReusableCell(using: self.castRegistration, for: indexPath, item: model)
            }
        }
    }()

    public override func mcvw_setupUI() {
        backgroundColor = .black
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        _ = storyRegistration
        _ = castRegistration
        _ = dataSource
    }

    public func bindInput(_ input: MCCGuideViewInput) {
        input.models
            .receive(on: DispatchQueue.main)
            .sink { [weak self] models in
                self?.applyModels(models)
            }
            .store(in: &cancellables)
    }

    public func mcvw_setCastLeadPreview(image: UIImage?) {
        castLeadPreviewImage = image
        guard let index = models.firstIndex(where: { if case .cast = $0 { true } else { false } }) else { return }
        let item = models[index]
        var snapshot = dataSource.snapshot()
        guard snapshot.indexOfItem(item) != nil else {
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            return
        }
        snapshot.reloadItems([item])
        dataSource.apply(snapshot, animatingDifferences: false)
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

    private func handlePrimary(at index: Int) {
        let now = Date()
        if let li = lastPrimaryIndex, li == index, let last = lastPrimaryAt, now.timeIntervalSince(last) < 0.5 {
            return
        }
        lastPrimaryIndex = index
        lastPrimaryAt = now
        guard index >= 0, index < models.count else { return }
        let model = models[index]
        let isLast = index == models.count - 1
        outputSubject.send(.primaryTapped(index: index, model: model, isLastPage: isLast))
        if !isLast {
            let offsetX = MCCScreenSize.width * CGFloat(index + 1)
            collectionView.setContentOffset(.init(x: offsetX, y: 0), animated: true)
        }
    }

}

private enum MCCGuideStyle {
    static let accent = UIColor(hex: "0077FF")!
    static let subtitle = UIColor.white.withAlphaComponent(0.4)
    static let buttonHeight: CGFloat = 48
    /// 副标题多行时的额外行距（在系统行高之上）
    static let detailLineSpacing: CGFloat = 4
    /// 与素材一致：宽:高 = 375:520
    static let storyHeroWidth: CGFloat = 375
    static let storyHeroHeight: CGFloat = 520
}

private func mccg_detailBodyAttributed(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
    let p = NSMutableParagraphStyle()
    p.lineSpacing = MCCGuideStyle.detailLineSpacing
    p.alignment = .center
    return NSAttributedString(string: text, attributes: [
        .paragraphStyle: p,
        .font: font,
        .foregroundColor: color
    ])
}

public final class MCCGuideStoryCell: MCCBaseCollectionViewCell {

    public var onPrimary: (() -> Void)?

    private let heroContainer = UIView()

    private let heroImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        v.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return v
    }()

    private let heroGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.cgColor,
        ]
        g.locations = [0.45, 1]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        return g
    }()

    private let titleLab: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 28, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let detailLab: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = MCCGuideStyle.subtitle
        l.textAlignment = .center
        return l
    }()

    private lazy var handleBtn: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = MCCGuideStyle.accent
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.clipsToBounds = true
        b.layer.cornerRadius = MCCGuideStyle.buttonHeight * 0.5
        b.addTarget(self, action: #selector(mccg_primaryTapped), for: .touchUpInside)
        return b
    }()

    public override func mcvw_setupUI() {
        contentView.backgroundColor = .black
        contentView.addSubview(heroContainer)
        heroContainer.layer.addSublayer(heroGradient)
        heroContainer.addSubview(heroImageView)
        heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let heroHMult = MCCGuideStyle.storyHeroHeight / MCCGuideStyle.storyHeroWidth
        heroContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(heroContainer.snp.width).multipliedBy(heroHMult)
        }

        contentView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.top.equalTo(heroContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        contentView.addSubview(detailLab)
        detailLab.snp.makeConstraints { make in
            make.top.equalTo(titleLab.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        contentView.addSubview(handleBtn)
        handleBtn.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(MCCGuideStyle.buttonHeight)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        heroGradient.frame = heroContainer.bounds
        let h = handleBtn.bounds.height
        if h > 0 { handleBtn.layer.cornerRadius = h * 0.5 }
    }

    public func mcvw_apply(model: MCSGuide) {
        guard case let .story(media, title, detail, button) = model else { return }
        titleLab.text = title
        detailLab.attributedText = mccg_detailBodyAttributed(
            detail,
            font: .systemFont(ofSize: 16, weight: .regular),
            color: MCCGuideStyle.subtitle
        )
        handleBtn.setTitle(button, for: .normal)
        handleBtn.layer.cornerRadius = MCCGuideStyle.buttonHeight * 0.5
        let trimmed = media.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let asset = UIImage(named: trimmed) {
            heroImageView.sd_cancelCurrentImageLoad()
            heroImageView.image = asset
            heroImageView.backgroundColor = .clear
        } else if let u = URL(string: trimmed), u.scheme != nil, !trimmed.isEmpty {
            heroImageView.sd_setImage(with: u, placeholderImage: nil)
        } else {
            heroImageView.sd_cancelCurrentImageLoad()
            heroImageView.image = nil
            heroImageView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        onPrimary = nil
        heroImageView.sd_cancelCurrentImageLoad()
        heroImageView.image = nil
    }

    @objc private func mccg_primaryTapped() {
        onPrimary?()
    }

}

public final class MCCGuideCastCell: MCCBaseCollectionViewCell {

    public var onPrimary: (() -> Void)?

    public var onPickPhoto: (() -> Void)?

    private let titleLab: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 28, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let detailLab: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = MCCGuideStyle.subtitle
        l.textAlignment = .center
        return l
    }()

    private let ringContainer = UIView()

    private let ringBorder = UIView()

    private let previewImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    private let uploadHintLabel: UILabel = {
        let l = UILabel()
        l.text = "Upload a photo"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private lazy var pickStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [ringContainer, uploadHintLabel])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 24
        s.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(mccg_pickTapped))
        s.addGestureRecognizer(tap)
        return s
    }()

    private lazy var handleBtn: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = MCCGuideStyle.accent
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.clipsToBounds = true
        b.layer.cornerRadius = MCCGuideStyle.buttonHeight * 0.5
        b.addTarget(self, action: #selector(mccg_primaryTapped), for: .touchUpInside)
        return b
    }()

    private var ringDiameter: CGFloat = 160

    public override func mcvw_setupUI() {
        contentView.backgroundColor = .black
        contentView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide.snp.top).offset(74)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        contentView.addSubview(detailLab)
        detailLab.snp.makeConstraints { make in
            make.top.equalTo(titleLab.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        contentView.addSubview(pickStack)
        pickStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }

        ringDiameter = min(MCCScreenSize.width * 0.42, 200)
        ringContainer.snp.makeConstraints { make in
            make.width.height.equalTo(ringDiameter)
        }

        let hairline: CGFloat = 1.0 / max(UIScreen.main.scale, 1)
        ringBorder.layer.borderWidth = hairline
        ringBorder.layer.borderColor = MCCGuideStyle.accent.cgColor
        ringBorder.layer.cornerRadius = ringDiameter / 2
        ringBorder.clipsToBounds = true
        ringContainer.addSubview(ringBorder)
        ringBorder.snp.makeConstraints { $0.edges.equalToSuperview() }

        ringBorder.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8 + hairline)
        }

        contentView.addSubview(handleBtn)
        handleBtn.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(MCCGuideStyle.buttonHeight)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let h = handleBtn.bounds.height
        if h > 0 { handleBtn.layer.cornerRadius = h * 0.5 }
        let w = previewImageView.bounds.width
        if w > 0 { previewImageView.layer.cornerRadius = w * 0.5 }
    }

    public func mcvw_apply(model: MCSGuide, previewImage: UIImage?) {
        guard case let .cast(title, detail, button) = model else { return }
        titleLab.text = title
        detailLab.attributedText = mccg_detailBodyAttributed(
            detail,
            font: .systemFont(ofSize: 16, weight: .regular),
            color: MCCGuideStyle.subtitle
        )
        handleBtn.setTitle(button, for: .normal)
        handleBtn.layer.cornerRadius = MCCGuideStyle.buttonHeight * 0.5
        if let img = previewImage {
            previewImageView.image = img
        } else {
            previewImageView.image = UIImage(named: "ic_cm_role")
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        onPrimary = nil
        onPickPhoto = nil
    }

    @objc private func mccg_primaryTapped() {
        onPrimary?()
    }

    @objc private func mccg_pickTapped() {
        onPickPhoto?()
    }

}
