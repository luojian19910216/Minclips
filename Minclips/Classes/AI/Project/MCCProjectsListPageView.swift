import UIKit
import SnapKit
import SDWebImage

public final class MCCProjectsListPageView: MCCBaseView {
    
    private static let mcvw_horizontalSectionInset: CGFloat = 4
    
    public let mcvw_runsWaterfallLayout: MCCShotsWaterfallLayout = {
        let l = MCCShotsWaterfallLayout()
        l.columnCount = 3
        let h = MCCProjectsListPageView.mcvw_horizontalSectionInset
        l.sectionInset = UIEdgeInsets(top: 4, left: h, bottom: 4, right: h)
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 4
        return l
    }()
    
    public lazy var mcvw_likesWaterfallLayout: MCCShotsWaterfallLayout = {
        let l = MCCShotsWaterfallLayout()
        l.columnCount = 3
        let h = MCCProjectsListPageView.mcvw_horizontalSectionInset
        l.sectionInset = UIEdgeInsets(top: 4, left: h, bottom: 4, right: h)
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 16
        return l
    }()
    
    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_runsWaterfallLayout)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCProjectsRunCell.self, forCellWithReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId)
        return cv
    }()
    
    public func mcvw_runsWaterfallColumnWidth(collectionWidth w: CGFloat) -> CGFloat {
        let width = (w > 0 ? w : UIScreen.main.bounds.width)
        let l = mcvw_runsWaterfallLayout
        let inner = width - l.sectionInset.left - l.sectionInset.right
        let cols = max(1, l.columnCount)
        let spacing = CGFloat(cols - 1) * l.minimumInteritemSpacing
        return max(1, (inner - spacing) / CGFloat(cols))
    }
    
    public func mcvw_activateRunsWaterfallLayout() {
        mcvw_collectionView.setCollectionViewLayout(mcvw_runsWaterfallLayout, animated: false)
    }
    
    public func mcvw_activateLikesWaterfallLikeHome() {
        mcvw_collectionView.register(
            MCCShotsListItemCell.self,
            forCellWithReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId
        )
        mcvw_collectionView.setCollectionViewLayout(mcvw_likesWaterfallLayout, animated: false)
    }
    
    public func mcvw_likesWaterfallColumnWidth(collectionWidth w: CGFloat) -> CGFloat {
        let width = (w > 0 ? w : UIScreen.main.bounds.width)
        let l = mcvw_likesWaterfallLayout
        let inner = width - l.sectionInset.left - l.sectionInset.right
        let cols = max(1, l.columnCount)
        let spacing = CGFloat(cols - 1) * l.minimumInteritemSpacing
        return max(1, (inner - spacing) / CGFloat(cols))
    }
    
    public private(set) var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay?
    
    public func mcvw_configureListSkeleton(isLikesLayout: Bool) {
        mcvw_skeletonOverlay?.removeFromSuperview()
        let style: MCCGradientHomeSkeletonOverlay.MCCStyle = isLikesLayout
        ? .projectsLikesThreeColumn
        : .projectsRunsThreeColumn
        let o = MCCGradientHomeSkeletonOverlay(style: style)
        addSubview(o)
        o.snp.makeConstraints { $0.edges.equalToSuperview() }
        o.isHidden = true
        mcvw_skeletonOverlay = o
    }
    
    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    public func mcvw_setListSkeletonVisible(_ visible: Bool) {
        guard let overlay = mcvw_skeletonOverlay else { return }
        if visible {
            overlay.mcvw_showHomeSkeleton()
        } else {
            overlay.mcvw_hideHomeSkeleton()
        }
    }
    
}

public final class MCCProjectsRunCell: MCCBaseCollectionViewCell {
    
    public static let mcvw_reuseId = "MCCProjectsRunCell"
    
    public let mcvw_imageContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()
    
    /// Static raster previews (user PNG / JPEG / static covers). Template feed tiles use `SDAnimatedImageView` + WebP instead.
    public let mcvw_thumbView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()
    
    /// Blur overlay on user image when generating / pending.
    public let mcvw_blurOverlay: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.isHidden = true
        v.isUserInteractionEnabled = false
        return v
    }()
    
    /// Centered failure / restricted badge (above blur & thumb).
    public let mcvw_failureBadgeContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }()
    
    public let mcvw_failureBadgeStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .center
        v.spacing = 12
        v.isLayoutMarginsRelativeArrangement = false
        return v
    }()
    
    public let mcvw_failureIconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        return v
    }()
    
    public let mcvw_failureTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        return l
    }()

    public let mcvw_failureSubtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textAlignment = .center
        l.textColor = UIColor.white.withAlphaComponent(0.55)
        l.numberOfLines = 2
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        return l
    }()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        mcvw_imageContainer.addSubview(mcvw_thumbView)
        mcvw_imageContainer.addSubview(mcvw_blurOverlay)
        mcvw_failureBadgeStack.addArrangedSubview(mcvw_failureIconView)
        mcvw_failureBadgeStack.addArrangedSubview(mcvw_failureTitleLabel)
        mcvw_failureBadgeStack.addArrangedSubview(mcvw_failureSubtitleLabel)
        mcvw_failureBadgeStack.setCustomSpacing(4, after: mcvw_failureTitleLabel)
        mcvw_failureBadgeContainer.addSubview(mcvw_failureBadgeStack)
        mcvw_imageContainer.addSubview(mcvw_failureBadgeContainer)
        
        mcvw_imageContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_thumbView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_blurOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        mcvw_failureBadgeStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        mcvw_failureBadgeContainer.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-4)
        }
        
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_thumbView.image = nil
        mcvw_thumbView.sd_cancelCurrentImageLoad()
        mcvw_blurOverlay.isHidden = true
        mcvw_failureBadgeContainer.isHidden = true
        mcvw_failureIconView.image = nil
        mcvw_failureTitleLabel.text = nil
        mcvw_failureSubtitleLabel.text = nil
        mcvw_failureSubtitleLabel.isHidden = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let w = max(0, mcvw_failureBadgeContainer.bounds.width - 8)
        mcvw_failureTitleLabel.preferredMaxLayoutWidth = w
        mcvw_failureSubtitleLabel.preferredMaxLayoutWidth = w
    }

}
