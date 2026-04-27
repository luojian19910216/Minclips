import UIKit
import Common
import SnapKit

public final class MCCSettingsView: MCCBaseView {

    private enum MCEMetric {
        static let cardCorner: CGFloat = 12
        static let contentHorizontal: CGFloat = 20
        static let cardInnerHorizontal: CGFloat = 16
        static let rowHeight: CGFloat = 56
        static let cardSpacing: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let titleValueGap: CGFloat = 12
        static let valueCopyGap: CGFloat = 8
    }

    private static let mcvw_textPrimary: UIColor = .white
    private static let mcvw_textSecondary: UIColor = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
    private static let mcvw_cardBackground: UIColor = UIColor(hex: "1C1C1E")!

    public var mcvw_onCopyUserId: (() -> Void)?

    public var mcvw_onFeedback: (() -> Void)?

    public var mcvw_onContact: (() -> Void)?

    public var mcvw_onTerms: (() -> Void)?

    public var mcvw_onPrivacy: (() -> Void)?

    private let mcvw_scrollView: UIScrollView = {
        let s = UIScrollView()
        s.alwaysBounceVertical = true
        s.showsVerticalScrollIndicator = true
        s.keyboardDismissMode = .onDrag
        s.backgroundColor = .clear
        return s
    }()

    private let mcvw_contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = MCEMetric.cardSpacing
        return s
    }()

    private let mcvw_userIdValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = MCCSettingsView.mcvw_textSecondary
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .right
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.text = "—"
        return l
    }()

    private lazy var mcvw_copyUserIdButton: UIButton = {
        let b = UIButton(type: .system)
        let img = UIImage(systemName: "doc.on.doc", withConfiguration: MCCSettingsView.mcvw_symbolConfigSmall())
        b.setImage(img?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.tintColor = MCCSettingsView.mcvw_textSecondary
        b.accessibilityLabel = "Copy"
        b.addTarget(self, action: #selector(mcvw_copyUserIdTapped), for: .touchUpInside)
        return b
    }()

    private let mcvw_versionLabel: UILabel = {
        let l = UILabel()
        l.textColor = MCCSettingsView.mcvw_textSecondary
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "000000")

        addSubview(mcvw_scrollView)
        mcvw_scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }

        mcvw_scrollView.addSubview(mcvw_contentStack)
        mcvw_contentStack.snp.makeConstraints { make in
            make.top.equalTo(mcvw_scrollView.contentLayoutGuide.snp.top).offset(8)
            make.leading.equalTo(mcvw_scrollView.frameLayoutGuide.snp.leading)
                .offset(MCEMetric.contentHorizontal)
            make.trailing.equalTo(mcvw_scrollView.frameLayoutGuide.snp.trailing)
                .offset(-MCEMetric.contentHorizontal)
            make.bottom.equalTo(mcvw_scrollView.contentLayoutGuide.snp.bottom).offset(-32)
        }

        mcvw_contentStack.addArrangedSubview(mcvw_makeUserCard())
        mcvw_contentStack.addArrangedSubview(
            mcvw_makeVCard(
                first: mcvw_makeChevronRow(
                    systemName: "text.bubble",
                    title: "Feedback",
                    action: { [weak self] in self?.mcvw_onFeedback?() }
                ),
                second: mcvw_makeChevronRow(
                    systemName: "envelope",
                    title: "Contact Us",
                    action: { [weak self] in self?.mcvw_onContact?() }
                )
            )
        )
        let legal = mcvw_makeVCard(
            first: mcvw_makeChevronRow(
                systemName: "book",
                title: "Terms of Service",
                action: { [weak self] in self?.mcvw_onTerms?() }
            ),
            second: mcvw_makeChevronRow(
                systemName: "checkmark.shield",
                title: "Privacy Policy",
                action: { [weak self] in self?.mcvw_onPrivacy?() }
            )
        )
        mcvw_contentStack.addArrangedSubview(legal)
        mcvw_contentStack.setCustomSpacing(24, after: legal)
        mcvw_contentStack.addArrangedSubview(mcvw_versionLabel)
        mcvw_versionLabel.snp.makeConstraints { $0.height.greaterThanOrEqualTo(20) }
    }

    public func mcvw_setUserIdDisplay(_ text: String) {
        mcvw_userIdValueLabel.text = text
    }

    public func mcvw_setVersionText(_ text: String) {
        mcvw_versionLabel.text = text
    }

    @objc private func mcvw_copyUserIdTapped() {
        mcvw_onCopyUserId?()
    }

    private static func mcvw_symbolConfigSmall() -> UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .default)
    }

    private static func mcvw_symbolConfigRow() -> UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)
    }

    private func mcvw_templateIcon(named: String) -> UIImageView {
        let v = UIImageView()
        let base = UIImage(systemName: named, withConfiguration: MCCSettingsView.mcvw_symbolConfigRow())
        v.image = base?.withRenderingMode(.alwaysTemplate)
        v.tintColor = MCCSettingsView.mcvw_textSecondary
        v.contentMode = .scaleAspectFit
        return v
    }

    private func mcvw_makeCardContainer() -> UIView {
        let c = UIView()
        c.backgroundColor = MCCSettingsView.mcvw_cardBackground
        c.layer.cornerRadius = MCEMetric.cardCorner
        c.clipsToBounds = true
        return c
    }

    private func mcvw_makeUserCard() -> UIView {
        let card = mcvw_makeCardContainer()
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(MCEMetric.rowHeight) }

        let icon = mcvw_templateIcon(named: "person.crop.circle")
        let title = UILabel()
        title.text = "User ID"
        title.textColor = MCCSettingsView.mcvw_textPrimary
        title.font = .systemFont(ofSize: 17, weight: .regular)
        title.setContentHuggingPriority(.required, for: .horizontal)
        title.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addSubview(icon)
        row.addSubview(title)
        row.addSubview(mcvw_userIdValueLabel)
        row.addSubview(mcvw_copyUserIdButton)

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(MCEMetric.iconSize)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(MCEMetric.titleValueGap)
            make.centerY.equalToSuperview()
        }
        mcvw_copyUserIdButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        mcvw_userIdValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(mcvw_copyUserIdButton.snp.leading).offset(-MCEMetric.valueCopyGap)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(title.snp.trailing).offset(8)
        }

        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        return card
    }

    private func mcvw_makeVCard(first: UIView, second: UIView) -> UIView {
        let card = mcvw_makeCardContainer()
        let sep = UIView()
        sep.backgroundColor = UIColor(white: 0.18, alpha: 1)
        let hairline: CGFloat = 1.0 / max(UIScreen.main.scale, 1)
        sep.snp.makeConstraints { $0.height.equalTo(hairline) }
        let stack = UIStackView(arrangedSubviews: [first, sep, second])
        stack.axis = .vertical
        stack.alignment = .fill
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        return card
    }

    private func mcvw_makeChevronRow(systemName: String, title: String, action: @escaping () -> Void) -> UIView {
        let row = UIControl()
        row.accessibilityLabel = title
        row.snp.makeConstraints { $0.height.equalTo(MCEMetric.rowHeight) }
        let icon = mcvw_templateIcon(named: systemName)
        let t = UILabel()
        t.text = title
        t.textColor = MCCSettingsView.mcvw_textPrimary
        t.font = .systemFont(ofSize: 17, weight: .regular)
        let chev = UIImageView(
            image: UIImage(systemName: "chevron.right", withConfiguration: MCCSettingsView.mcvw_symbolConfigSmall())?
                .withRenderingMode(.alwaysTemplate)
        )
        chev.tintColor = MCCSettingsView.mcvw_textSecondary
        chev.contentMode = .center
        row.addSubview(icon)
        row.addSubview(t)
        row.addSubview(chev)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(MCEMetric.iconSize)
        }
        t.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(MCEMetric.titleValueGap)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chev.snp.leading).offset(-8)
        }
        chev.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        row.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return row
    }

}
