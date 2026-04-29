import UIKit

/// 列表缩略图顶部叠色（黑 72% → 透明）；高度与 `MCCShotsListItemMetrics.listItemImageTopGradientHeight` 配套。
public final class MCCListItemImageTopFadeView: UIView {

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        let gradient = layer as! CAGradientLayer
        gradient.colors = [UIColor.black.withAlphaComponent(0.72).cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
