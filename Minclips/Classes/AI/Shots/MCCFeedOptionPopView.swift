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

    private var mcvw_rowPick: ((Int) -> Void)?

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

    public func mcvw_setRows(_ rows: [MCCFeedOptionRow], onSelect: @escaping (Int) -> Void) {
        mcvw_rowPick = onSelect
        mcvw_optionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (idx, row) in rows.enumerated() {
            let line = mcvw_makeLineView(row: row, index: idx, isLast: idx == rows.count - 1)
            mcvw_optionStack.addArrangedSubview(line)
            line.snp.makeConstraints { $0.height.equalTo(52) }
        }
    }

    @objc
    private func mcvw_lineTapped(_ s: UIControl) {
        mcvw_rowPick?(s.tag)
    }

    private func mcvw_makeLineView(row: MCCFeedOptionRow, index: Int, isLast: Bool) -> UIControl {
        let c = UIControl()
        c.accessibilityLabel = row.title
        c.tag = index
        c.addTarget(self, action: #selector(mcvw_lineTapped(_:)), for: .touchUpInside)
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
            h.addArrangedSubview(MCCFeedOptionPopView.mcvw_proPillView())
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

    private static func mcvw_proPillView() -> UIView {
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
