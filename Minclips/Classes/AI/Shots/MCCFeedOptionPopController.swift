import UIKit
import Common
import SnapKit

public struct MCCFeedOptionRow: Sendable {
    public var title: String
    public var isPro: Bool
    public var isSelected: Bool
    public init(title: String, isPro: Bool, isSelected: Bool) {
        self.title = title
        self.isPro = isPro
        self.isSelected = isSelected
    }
}

public final class MCCFeedOptionPopView: MCCBasePopView {

    public let mcvw_optionStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.alignment = .fill
        return s
    }()

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cardView.backgroundColor = UIColor(white: 0.12, alpha: 0.98)
        cardView.addSubview(mcvw_optionStack)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        mcvw_optionStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }
}

public final class MCCFeedOptionPopController: MCCPopController<MCCFeedOptionPopView, MCCEmptyViewModel> {

    public var mcvc_onSelectIndex: ((Int) -> Void)?
    
    private var mcvc_rowPick: ((Int) -> Void)?
    
    public override func mcvc_init() {
        super.mcvc_init()
        animationStyle = .easeInEaseOut
        dimmingInsets = .zero
    }
    
    public func mcvc_applyRows(_ rows: [MCCFeedOptionRow], onSelect: @escaping (Int) -> Void) {
        mcvc_rowPick = { [weak self] i in
            onSelect(i)
            self?.mcvc_onSelectIndex?(i)
            self?.dismiss(animated: true)
        }
        let stack = contentView.mcvw_optionStack
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (idx, row) in rows.enumerated() {
            let line = mcvc_lineView(row: row, index: idx, isLast: idx == rows.count - 1)
            stack.addArrangedSubview(line)
            line.snp.makeConstraints { $0.height.equalTo(52) }
        }
    }

    @objc
    private func mcvc_lineTapped(_ s: UIControl) {
        mcvc_rowPick?(s.tag)
    }

    private func mcvc_lineView(row: MCCFeedOptionRow, index: Int, isLast: Bool) -> UIControl {
        let c = UIControl()
        c.accessibilityLabel = row.title
        c.tag = index
        c.addTarget(self, action: #selector(mcvc_lineTapped(_:)), for: .touchUpInside)
        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        h.isUserInteractionEnabled = false
        let t = UILabel()
        t.text = row.title
        t.textColor = .white
        t.font = .systemFont(ofSize: 16, weight: .medium)
        h.addArrangedSubview(t)
        if row.isPro {
            h.addArrangedSubview(MCCFeedOptionPopController.mcvc_proPillView())
        }
        h.addArrangedSubview(UIView())
        if row.isSelected {
            let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            check.tintColor = UIColor(hex: "00AAFF")!
            check.contentMode = .scaleAspectFit
            check.snp.makeConstraints { $0.size.equalTo(22) }
            h.addArrangedSubview(check)
        }
        c.addSubview(h)
        h.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        sep.isHidden = isLast
        c.addSubview(sep)
        sep.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return c
    }

    private static func mcvc_proPillView() -> UIView {
        let w = UIView()
        w.backgroundColor = UIColor.systemYellow
        w.layer.cornerRadius = 4
        w.clipsToBounds = true
        let l = UILabel()
        l.text = "PRO"
        l.textColor = .black
        l.font = .systemFont(ofSize: 10, weight: .bold)
        w.addSubview(l)
        l.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(5)
        }
        w.snp.makeConstraints { $0.height.equalTo(18) }
        return w
    }
}
