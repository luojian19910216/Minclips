import UIKit
import Common
import SnapKit
import SDWebImage
import Data

/// 列表里正在播的 WebP 状态，用于详情页无缝续播（同一 `UIImage` + 帧位置）。
public struct MCCWebpPlaybackHandoff {
    public let image: UIImage
    public let frameIndex: UInt
    public let loopCount: UInt
}

public final class MCCFeedDetailView: MCCBaseView {

    private let mcvw_mediaContainer = UIView()

    private let mcvw_posterImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    private let mcvw_webpImageView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public override func mcvw_setupUI() {
        backgroundColor = .clear
        addSubview(mcvw_mediaContainer)
        mcvw_mediaContainer.layer.cornerRadius = 12
        mcvw_mediaContainer.clipsToBounds = true
        mcvw_mediaContainer.addSubview(mcvw_posterImageView)
        mcvw_mediaContainer.addSubview(mcvw_webpImageView)
        mcvw_mediaContainer.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(mcvw_mediaContainer.snp.width).multipliedBy(MCCShotsListItemMetrics.imageHeightPerWidth)
        }
        mcvw_posterImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_webpImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func mcvw_configure(feedItem: MCSFeedItem, webpHandoff: MCCWebpPlaybackHandoff?, thumbnailPixelSize: CGSize) {
        let ctx: [SDWebImageContextOption: Any] = [
            .imageThumbnailPixelSize: NSValue(cgSize: thumbnailPixelSize),
            .imagePreserveAspectRatio: true
        ]
        let asset = feedItem.videoAsset
        if let u = URL(string: asset.posterImageUrl), !asset.posterImageUrl.isEmpty {
            mcvw_posterImageView.sd_setImage(with: u, placeholderImage: nil, options: [], context: ctx)
        } else {
            mcvw_posterImageView.sd_cancelCurrentImageLoad()
            mcvw_posterImageView.image = nil
        }
        if let h = webpHandoff {
            mcvw_applyWebpHandoff(h)
        } else if let u = URL(string: asset.webpImageUrl), !asset.webpImageUrl.isEmpty {
            mcvw_webpImageView.autoPlayAnimatedImage = true
            mcvw_webpImageView.isHidden = false
            mcvw_webpImageView.sd_setImage(with: u, placeholderImage: nil, options: [], completed: { [weak self] _, _, _, _ in
                self?.mcvw_webpImageView.startAnimating()
            })
        } else {
            mcvw_webpImageView.sd_cancelCurrentImageLoad()
            mcvw_webpImageView.image = nil
            mcvw_webpImageView.isHidden = true
        }
    }

    private func mcvw_applyWebpHandoff(_ h: MCCWebpPlaybackHandoff) {
        mcvw_webpImageView.sd_cancelCurrentImageLoad()
        mcvw_webpImageView.autoPlayAnimatedImage = false
        mcvw_webpImageView.isHidden = false
        mcvw_webpImageView.image = h.image
        mcvw_webpImageView.player?.seekToFrame(at: h.frameIndex, loopCount: h.loopCount)
        mcvw_webpImageView.autoPlayAnimatedImage = true
        mcvw_webpImageView.startAnimating()
    }

}
