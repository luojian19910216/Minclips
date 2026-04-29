import UIKit

public enum MCCRootTabNavChrome {

    public static func leftTitleBarButtonItem(title: String) -> UIBarButtonItem {
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .semibold)
        label.sizeToFit()
        let item = UIBarButtonItem(customView: label)
        if #available(iOS 26.0, *) {
            item.hidesSharedBackground = true
        }
        return item
    }

    /// 统一右侧胶囊：`title == nil` 为单图标（圆形 44×44），否则 icon + title（宽度自适应）。
    /// iOS 26+ 走系统液态玻璃 capsule；iOS<26 自带 `UIBlurEffect(.regular)` + `white @ 0.06` 背景。
    public static func capsuleBarButtonItem(
        icon: UIImage?,
        title: String? = nil,
        titleColor: UIColor = .white,
        target: Any? = nil,
        action: Selector? = nil
    ) -> UIBarButtonItem {
        let b = MCCNavCapsuleButton(type: .custom)
        b.mcvw_apply(icon: icon, title: title, titleColor: titleColor)
        if let target, let action {
            b.addTarget(target, action: action, for: .touchUpInside)
        }
        return UIBarButtonItem(customView: b)
    }

    /// 动态文案（如详情积分）刷新：保留同一个 `UIBarButtonItem`，仅改 title 与重测宽度。
    public static func updateCapsuleBarButtonItem(_ item: UIBarButtonItem?, title: String) {
        guard let b = item?.customView as? MCCNavCapsuleButton else { return }
        b.mcvw_updateTitle(title)
    }

}

public final class MCCNavCapsuleButton: UIButton {

    private var mcvw_blurView: UIVisualEffectView?

    private var mcvw_tintOverlay: UIView?

    private var mcvw_iconOnly: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
        if #unavailable(iOS 26.0) {
            mcvw_installLegacyCapsule()
        }
    }

    /// 用在 navbar 之外（没有系统共享玻璃背景）时显式装胶囊 backdrop；幂等。
    /// iOS 26+ 用系统 `UIButton.Configuration.glass()`；iOS<26 装 blur+tint 胶囊。
    /// 调用前请先 `mcvw_apply(...)` 设好 icon/title。
    public func mcvw_useStandaloneCapsule() {
        if #available(iOS 26.0, *) {
            guard configuration == nil else { return }
            var cfg = UIButton.Configuration.glass()
            cfg.cornerStyle = .capsule
            if let img = image(for: .normal) { cfg.image = img }
            if let t = title(for: .normal) { cfg.title = t }
            configuration = cfg
        } else {
            guard mcvw_blurView == nil else { return }
            mcvw_installLegacyCapsule()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let r = bounds.height / 2
        mcvw_blurView?.frame = bounds
        mcvw_blurView?.layer.cornerRadius = r
        mcvw_tintOverlay?.frame = bounds
        mcvw_tintOverlay?.layer.cornerRadius = r
    }

    func mcvw_apply(icon: UIImage?, title: String?, titleColor: UIColor) {
        if let icon = icon {
            setImage(icon, for: .normal)
        }
        if let title = title {
            mcvw_iconOnly = false
            setTitle(title, for: .normal)
            setTitleColor(titleColor, for: .normal)
            titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            titleLabel?.lineBreakMode = .byClipping
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 17)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        } else {
            mcvw_iconOnly = true
            contentEdgeInsets = .zero
            titleEdgeInsets = .zero
        }
        mcvw_resize()
    }

    func mcvw_updateTitle(_ title: String) {
        setTitle(title, for: .normal)
        mcvw_resize()
    }

    private func mcvw_installLegacyCapsule() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blur.isUserInteractionEnabled = false
        blur.clipsToBounds = true
        let tint = UIView()
        tint.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        tint.isUserInteractionEnabled = false
        tint.clipsToBounds = true
        insertSubview(blur, at: 0)
        insertSubview(tint, aboveSubview: blur)
        mcvw_blurView = blur
        mcvw_tintOverlay = tint
    }

    private func mcvw_resize() {
        invalidateIntrinsicContentSize()
        sizeToFit()
        let w: CGFloat = mcvw_iconOnly ? 44 : max(76, ceil(bounds.width))
        bounds = CGRect(x: 0, y: 0, width: w, height: 44)
        frame = CGRect(x: 0, y: 0, width: w, height: 44)
    }

}
