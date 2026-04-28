import UIKit
import SnapKit
import SDWebImage
import Data

public enum MCCShotsListItemMetrics {

    public static let listItemImageContainerBackground: UIColor = UIColor.white.withAlphaComponent(0.06)

    public static let imageToTitleSpacing: CGFloat = 8

    public static let titleFont = UIFont.systemFont(ofSize: 14, weight: .regular)

    public static let titleLineHeight: CGFloat = 16

    public static let titleMaxLines = 2

    public static let imageHeightPerWidth: CGFloat = 16.0 / 9.0

    public static func titleTextAttributes(textColor: UIColor) -> [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle()
        p.minimumLineHeight = titleLineHeight
        p.maximumLineHeight = titleLineHeight
        return [.font: titleFont, .paragraphStyle: p, .foregroundColor: textColor]
    }

    public static func feedImageThumbnailPixelSize(columnWidthPoints: CGFloat, heightPerWidth: CGFloat = imageHeightPerWidth) -> CGSize {
        let scale = UIScreen.main.scale
        let ptW = max(1, columnWidthPoints)
        let ptH = ptW * heightPerWidth
        return CGSize(width: ptW * scale, height: ptH * scale)
    }

    public static let sdPosterLoadOptions: SDWebImageOptions = [.highPriority]

    public static let sdWebpAnimatedLoadOptions: SDWebImageOptions = [.lowPriority]

    public static func sdPosterThumbnailContext(thumbnailPixelSize: CGSize) -> [SDWebImageContextOption: Any] {
        [
            .imageThumbnailPixelSize: NSValue(cgSize: thumbnailPixelSize),
            .imagePreserveAspectRatio: true
        ]
    }

}

public final class MCCShotsListPageView: MCCBaseView {

    public lazy var mcvw_waterfallLayout: MCCShotsWaterfallLayout = {
        let l = MCCShotsWaterfallLayout()
        l.columnCount = 2
        l.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 0, right: 4)
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 16
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_waterfallLayout)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCShotsListItemCell.self, forCellWithReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId)
        return cv
    }()

    public lazy var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay = {
        let item = MCCGradientHomeSkeletonOverlay(style: .doubleColumnGrid)
        item.isHidden = true
        return item
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(mcvw_skeletonOverlay)
        mcvw_skeletonOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func mcvw_setListSkeletonVisible(_ visible: Bool) {
        if visible {
            mcvw_skeletonOverlay.mcvw_showHomeSkeleton()
        } else {
            mcvw_skeletonOverlay.mcvw_hideHomeSkeleton()
        }
    }

}

public final class MCCShotsListItemCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCShotsListItemCell"

    public let mcvw_imageContainer = UIView()

    public let mcvw_posterImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_webpImageView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_durationLabel = UILabel()

    public let mcvw_proBadge = UIView()

    public let mcvw_proIcon: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.image = UIImage(named: "ic_nav_pro")
        v.tintColor = nil
        return v
    }()

    public let mcvw_titleLabel = UILabel()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        contentView.addSubview(mcvw_titleLabel)
        mcvw_imageContainer.addSubview(mcvw_posterImageView)
        mcvw_imageContainer.addSubview(mcvw_webpImageView)
        mcvw_imageContainer.addSubview(mcvw_durationLabel)
        mcvw_imageContainer.addSubview(mcvw_proBadge)
        mcvw_proBadge.addSubview(mcvw_proIcon)
        mcvw_proBadge.backgroundColor = UIColor(white: 0, alpha: 0.24)
        mcvw_proBadge.layer.cornerRadius = 14
        mcvw_proBadge.clipsToBounds = true
        mcvw_imageContainer.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        mcvw_imageContainer.layer.cornerRadius = 12
        mcvw_imageContainer.clipsToBounds = true
        mcvw_posterImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_webpImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_setImageHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        mcvw_titleLabel.font = MCCShotsListItemMetrics.titleFont
        mcvw_titleLabel.numberOfLines = MCCShotsListItemMetrics.titleMaxLines
        mcvw_titleLabel.lineBreakMode = .byTruncatingTail
        mcvw_titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mcvw_imageContainer.snp.bottom).offset(MCCShotsListItemMetrics.imageToTitleSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_durationLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.equalToSuperview().inset(8)
        }
        mcvw_proBadge.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
            make.size.equalTo(28)
        }
        mcvw_proIcon.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_setImageHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        mcvw_proBadge.isHidden = true
        mcvw_posterImageView.sd_cancelCurrentImageLoad()
        mcvw_posterImageView.image = nil
        mcvw_clearWebpAnimated()
    }

    public func mcvw_setImageHeightPerWidth(_ ratio: CGFloat) {
        mcvw_imageContainer.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(mcvw_imageContainer.snp.width).multipliedBy(ratio)
        }
    }

    public func mcvw_applyPosterOnly(posterUrl: String, thumbnailPixelSize: CGSize) {
        mcvw_clearWebpAnimated()
        mcvw_posterImageView.isHidden = false
        let ctx = MCCShotsListItemMetrics.sdPosterThumbnailContext(thumbnailPixelSize: thumbnailPixelSize)
        if let u = URL(string: posterUrl), !posterUrl.isEmpty {
            mcvw_posterImageView.sd_setImage(
                with: u,
                placeholderImage: nil,
                options: MCCShotsListItemMetrics.sdPosterLoadOptions,
                context: ctx
            )
        } else {
            mcvw_posterImageView.sd_cancelCurrentImageLoad()
            mcvw_posterImageView.image = nil
        }
    }

    public func mcvw_applyWebpAnimated(webpUrl: String, thumbnailPixelSize _: CGSize) {
        guard let u = URL(string: webpUrl), !webpUrl.isEmpty else {
            mcvw_clearWebpAnimated()
            return
        }
        mcvw_webpImageView.autoPlayAnimatedImage = true
        mcvw_webpImageView.isHidden = false
        mcvw_webpImageView.sd_setImage(
            with: u,
            placeholderImage: nil,
            options: MCCShotsListItemMetrics.sdWebpAnimatedLoadOptions,
            completed: { [weak self] image, error, _, _ in
                guard let self = self else { return }
                guard error == nil, image != nil else { return }
                self.mcvw_webpImageView.startAnimating()
                self.mcvw_posterImageView.isHidden = true
            }
        )
    }

    public func mcvw_clearWebpAnimated() {
        mcvw_webpImageView.sd_cancelCurrentImageLoad()
        mcvw_webpImageView.image = nil
        mcvw_webpImageView.isHidden = true
        mcvw_posterImageView.isHidden = false
    }

    public func mcvw_captureWebpPlaybackHandoff() -> MCCWebpPlaybackHandoff? {
        guard !mcvw_webpImageView.isHidden, let image = mcvw_webpImageView.image else { return nil }
        guard image.sd_imageFrameCount > 1 else { return nil }
        return MCCWebpPlaybackHandoff(
            image: image,
            frameIndex: UInt(mcvw_webpImageView.currentFrameIndex),
            loopCount: UInt(mcvw_webpImageView.currentLoopCount)
        )
    }

}
