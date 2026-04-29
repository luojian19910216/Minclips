import UIKit
import SnapKit
import SDWebImage
import Data

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

    /// Last `runId` applied to this cell — validates collection view index vs visible cell before navigation.
    public internal(set) var mcvw_boundRunId: String = ""

    /// Bumps on reuse and on each thumbnail bind so stray `sd_setImage` completions are ignored.
    private var mcvw_thumbLoadGeneration: UInt = 0

    private let mcvw_topImageGradientView = MCCListItemImageTopFadeView(frame: .zero)
    
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
    
    /// Frosted overlay for non‑success thumbnails (covers user upload + poster fallbacks uniformly).
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

    /// Success only — first output artifact duration (video workflows), top‑leading corner.
    public let mcvw_successDurationLabel: UILabel = {
        let l = UILabel()
        l.isHidden = true
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textAlignment = .natural
        l.textColor = UIColor.white.withAlphaComponent(0.48)
        l.backgroundColor = .clear
        return l
    }()

    /// Success only — holds `qualityTier` text (480p / 720p / 1080p) with dark chip background.
    public let mcvw_successQualityPill: UIView = {
        let v = UIView()
        v.isHidden = true
        v.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        v.layer.cornerRadius = 6
        v.clipsToBounds = true
        return v
    }()

    /// Success only — `qualityTier` label inside `mcvw_successQualityPill`.
    public let mcvw_successQualityLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textAlignment = .center
        l.textColor = UIColor.white.withAlphaComponent(0.72)
        l.backgroundColor = .clear
        return l
    }()

    private let mcvw_generatingOverlay: UIView = {
        let v = UIView()
        v.isHidden = true
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        return v
    }()

    private let mcvw_generatingDimView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = UIColor(red: 14 / 255, green: 21 / 255, blue: 40 / 255, alpha: 0.86)
        return v
    }()

    private let mcvw_generatingShimmer = MCCRunGeneratingShimmerView(frame: .zero)

    private let mcvw_generatingPercentLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowOpacity = 0.45
        l.layer.shadowRadius = 3
        l.layer.shadowOffset = .zero
        return l
    }()

    private let mcvw_generatingStatusLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 16, weight: .regular)
        return l
    }()

    private let mcvw_generatingTextStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 12
        s.isUserInteractionEnabled = false
        return s
    }()

    private var mcvw_generatingProgressTimer: Timer?
    private var mcvw_generatingElapsedAnchor: Date?

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        mcvw_imageContainer.addSubview(mcvw_thumbView)
        mcvw_imageContainer.addSubview(mcvw_topImageGradientView)
        mcvw_imageContainer.addSubview(mcvw_blurOverlay)
        mcvw_imageContainer.addSubview(mcvw_successDurationLabel)
        mcvw_imageContainer.addSubview(mcvw_successQualityPill)
        mcvw_successQualityPill.addSubview(mcvw_successQualityLabel)
        mcvw_failureBadgeStack.addArrangedSubview(mcvw_failureIconView)
        mcvw_failureBadgeStack.addArrangedSubview(mcvw_failureTitleLabel)
        mcvw_failureBadgeContainer.addSubview(mcvw_failureBadgeStack)
        mcvw_imageContainer.addSubview(mcvw_failureBadgeContainer)
        mcvw_generatingTextStack.addArrangedSubview(mcvw_generatingPercentLabel)
        mcvw_generatingTextStack.addArrangedSubview(mcvw_generatingStatusLabel)
        mcvw_generatingOverlay.addSubview(mcvw_generatingDimView)
        mcvw_generatingOverlay.addSubview(mcvw_generatingShimmer)
        mcvw_generatingOverlay.addSubview(mcvw_generatingTextStack)
        mcvw_imageContainer.addSubview(mcvw_generatingOverlay)
        
        mcvw_imageContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_thumbView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_topImageGradientView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(MCCShotsListItemMetrics.listItemImageTopGradientHeight)
        }
        mcvw_blurOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        mcvw_successDurationLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalToSuperview().offset(8)
        }

        mcvw_successQualityPill.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().offset(-8)
            $0.height.equalTo(20)
        }

        mcvw_successQualityLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-6)
        }
        
        mcvw_failureBadgeStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        mcvw_failureBadgeContainer.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-4)
        }

        mcvw_generatingOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_generatingDimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        mcvw_generatingShimmer.snp.makeConstraints { $0.edges.equalToSuperview() }

        mcvw_generatingTextStack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-4)
        }

        mcvw_generatingOverlay.bringSubviewToFront(mcvw_generatingTextStack)

    }

    /// Cancels stale decoding when the cell is recycled or bound to another run; completion handler ignores late frames.
    public func mcvw_bindThumbnail(remoteURL: URL?, blurOverlayShown: Bool) {
        mcvw_thumbLoadGeneration &+= 1
        let token = mcvw_thumbLoadGeneration
        mcvw_thumbView.sd_cancelCurrentImageLoad()
        guard let remoteURL else {
            mcvw_thumbView.image = nil
            mcvw_blurOverlay.isHidden = true
            return
        }
        mcvw_blurOverlay.isHidden = !blurOverlayShown
        mcvw_thumbView.image = nil
        mcvw_thumbView.sd_setImage(with: remoteURL, placeholderImage: nil, options: [.retryFailed]) { [weak self] _, _, _, _ in
            guard let self else { return }
            guard self.mcvw_thumbLoadGeneration == token else { return }
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_thumbLoadGeneration &+= 1
        mcvw_boundRunId = ""
        mcvw_thumbView.image = nil
        mcvw_thumbView.sd_cancelCurrentImageLoad()
        mcvw_blurOverlay.isHidden = true
        mcvw_failureBadgeContainer.isHidden = true
        mcvw_failureIconView.image = nil
        mcvw_failureTitleLabel.text = nil
        mcvw_successDurationLabel.isHidden = true
        mcvw_successDurationLabel.text = nil
        mcvw_successQualityPill.isHidden = true
        mcvw_successQualityLabel.text = nil
        mcvw_generatingOverlay.isHidden = true
        mcvw_generatingProgressTimer?.invalidate()
        mcvw_generatingProgressTimer = nil
        mcvw_generatingElapsedAnchor = nil
        mcvw_generatingPercentLabel.text = nil
        mcvw_generatingShimmer.mcvw_stopAnimating()
    }

    func mcvw_configureGeneratingOverlay(for run: MCSRunItem) {
        guard run.runState == .generating else {
            mcvw_generatingOverlay.isHidden = true
            mcvw_generatingProgressTimer?.invalidate()
            mcvw_generatingProgressTimer = nil
            mcvw_generatingElapsedAnchor = nil
            mcvw_generatingShimmer.mcvw_stopAnimating()
            return
        }
        mcvw_generatingOverlay.isHidden = false
        mcvw_generatingOverlay.bringSubviewToFront(mcvw_generatingTextStack)
        mcvw_generatingElapsedAnchor = run.createdAt
        mcvw_generatingStatusLabel.text = "Generating"
        mcvw_tickGeneratingPercentDisplay()
        mcvw_startGeneratingProgressTickerIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.mcvw_generatingOverlay.layoutIfNeeded()
            self.mcvw_generatingShimmer.layoutIfNeeded()
            self.mcvw_generatingShimmer.mcvw_startAnimating()
        }
    }

    private func mcvw_tickGeneratingPercentDisplay() {
        guard let anchor = mcvw_generatingElapsedAnchor else {
            mcvw_generatingPercentLabel.text = "0%"
            return
        }
        let elapsed = Date().timeIntervalSince(anchor)
        let p = MCCGenerationProgressSimulation.percent(elapsedSinceStart: elapsed)
        mcvw_generatingPercentLabel.text = "\(p)%"
    }

    private func mcvw_startGeneratingProgressTickerIfNeeded() {
        mcvw_generatingProgressTimer?.invalidate()
        let t = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.mcvw_tickGeneratingPercentDisplay()
        }
        RunLoop.main.add(t, forMode: .common)
        mcvw_generatingProgressTimer = t
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let w = max(0, mcvw_failureBadgeContainer.bounds.width - 8)
        mcvw_failureTitleLabel.preferredMaxLayoutWidth = w
    }

}
