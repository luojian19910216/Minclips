import UIKit
import Common
import SnapKit
import SDWebImage

public final class MCCToolsView: MCCBaseView {

    public let mcvw_flowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumInteritemSpacing = 12
        l.minimumLineSpacing = 12
        l.sectionInset = UIEdgeInsets(top: 24, left: 12, bottom: 24, right: 12)
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_flowLayout)
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .clear
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCToolCardCell.self, forCellWithReuseIdentifier: MCCToolCardCell.mcvw_id)
        return cv
    }()

    public lazy var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay = {
        MCCGradientHomeSkeletonOverlay(style: .singleColumnList)
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        addSubview(mcvw_skeletonOverlay)
        mcvw_skeletonOverlay.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_skeletonOverlay.isHidden = true
    }

    public func mcvw_setListSkeletonVisible(_ visible: Bool) {
        if visible {
            mcvw_skeletonOverlay.mcvw_showHomeSkeleton()
        } else {
            mcvw_skeletonOverlay.mcvw_hideHomeSkeleton()
        }
    }

}

public final class MCCToolCardCell: MCCBaseCollectionViewCell {

    public static let mcvw_id = "MCCToolCardCell"

    private static let mcvw_cardCornerRadius: CGFloat = 12

    private static let mcvw_borderWidth: CGFloat = 2

    private let mcvw_borderGradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(hex: "00AAFF", alpha: 0.12)!.cgColor,
            UIColor(hex: "00AAFF", alpha: 0)!.cgColor,
            UIColor(hex: "00AAFF", alpha: 0)!.cgColor,
            UIColor(hex: "00AAFF", alpha: 0.12)!.cgColor,
        ]
        g.locations = [0, NSNumber(value: 1.0 / 3.0), NSNumber(value: 2.0 / 3.0), 1]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        return g
    }()

    private let mcvw_borderMaskLayer: CAShapeLayer = {
        let m = CAShapeLayer()
        m.fillRule = .evenOdd
        m.fillColor = UIColor.white.cgColor
        return m
    }()

    private let mcvw_textStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 8
        return s
    }()

    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.numberOfLines = 2
        return l
    }()

    public let mcvw_subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.white.withAlphaComponent(0.4)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.numberOfLines = 2
        return l
    }()

    private let mcvw_iconContainer = UIView()

    private let mcvw_iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let mcvw_cornerTLImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "ic_gc_tl_00AAFF_80"))
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let mcvw_cornerBRImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "ic_gc_br_00AAFF_120"))
        v.contentMode = .scaleAspectFit
        return v
    }()

    public override func mcvw_setupUI() {
        contentView.backgroundColor = UIColor(hex: "D6F1FF", alpha: 0.06)!
        contentView.layer.cornerRadius = Self.mcvw_cardCornerRadius
        contentView.clipsToBounds = true

        contentView.layer.addSublayer(mcvw_borderGradientLayer)
        mcvw_borderGradientLayer.mask = mcvw_borderMaskLayer
        mcvw_borderGradientLayer.zPosition = 1

        contentView.addSubview(mcvw_cornerTLImageView)
        contentView.addSubview(mcvw_cornerBRImageView)

        mcvw_cornerTLImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        mcvw_cornerBRImageView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
        }

        mcvw_textStack.addArrangedSubview(mcvw_titleLabel)
        mcvw_textStack.addArrangedSubview(mcvw_subtitleLabel)

        contentView.addSubview(mcvw_textStack)
        contentView.addSubview(mcvw_iconContainer)
        mcvw_iconContainer.addSubview(mcvw_iconView)

        mcvw_textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(mcvw_iconContainer.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }

        mcvw_iconContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        mcvw_iconView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        mcvw_layoutGradientBorder()
    }

    private func mcvw_layoutGradientBorder() {
        let b = contentView.bounds
        guard b.width > 0, b.height > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mcvw_borderGradientLayer.frame = b
        mcvw_borderMaskLayer.frame = mcvw_borderGradientLayer.bounds

        let r = Self.mcvw_cardCornerRadius
        let bw = Self.mcvw_borderWidth
        let outer = UIBezierPath(roundedRect: b, cornerRadius: r)
        let insetRect = b.insetBy(dx: bw, dy: bw)
        let innerR = max(0, r - bw)
        let inner = UIBezierPath(roundedRect: insetRect, cornerRadius: innerR)
        outer.append(inner)
        outer.usesEvenOddFillRule = true
        mcvw_borderMaskLayer.path = outer.cgPath
        CATransaction.commit()
    }

    public func mcvw_apply(code: String, title: String, iconContent: String) {
        mcvw_titleLabel.text = code
        mcvw_subtitleLabel.text = title
        let trimmed = iconContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if let u = URL(string: trimmed), !trimmed.isEmpty {
            mcvw_iconView.sd_setImage(with: u, placeholderImage: nil)
        } else {
            mcvw_iconView.sd_cancelCurrentImageLoad()
            mcvw_iconView.image = nil
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_titleLabel.text = nil
        mcvw_subtitleLabel.text = nil
        mcvw_iconView.sd_cancelCurrentImageLoad()
        mcvw_iconView.image = nil
    }

}
