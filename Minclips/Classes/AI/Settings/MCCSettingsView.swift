import UIKit
import SnapKit

public final class MCCSettingsView: MCCBaseView {

    private enum MCEMetric {
        static let cardCorner: CGFloat = 12
        static let contentTopInset: CGFloat = 16
        static let contentHorizontal: CGFloat = 12
        static let cardInnerHorizontal: CGFloat = 12
        static let rowHeight: CGFloat = 52
        static let cardSpacing: CGFloat = 12
        static let contentBottomInset: CGFloat = 12
        static let iconSize: CGFloat = 20
        static let titleValueGap: CGFloat = 12
        static let valueCopyGap: CGFloat = 4
        static let versionBottomInset: CGFloat = 12
        static let versionScrollGap: CGFloat = 12
    }

    private static let mcvw_textPrimary: UIColor = .white
    private static let mcvw_textSecondary: UIColor = .white.withAlphaComponent(0.48)
    private static let mcvw_cardBackground: UIColor = UIColor.white.withAlphaComponent(0.06)

    public private(set) var mcvw_userIdLeadIconView: UIImageView!

    public lazy var mcvw_scrollView: UIScrollView = {
        let s = UIScrollView()
        s.alwaysBounceVertical = true
        s.showsVerticalScrollIndicator = true
        s.keyboardDismissMode = .onDrag
        s.backgroundColor = .clear
        return s
    }()

    public lazy var mcvw_contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = MCEMetric.cardSpacing
        return s
    }()

    public lazy var mcvw_userIdRowTitleLabel: UILabel = {
        let t = UILabel()
        t.textColor = MCCSettingsView.mcvw_textPrimary
        t.font = .systemFont(ofSize: 16, weight: .regular)
        t.setContentHuggingPriority(.required, for: .horizontal)
        t.setContentCompressionResistancePriority(.required, for: .horizontal)
        return t
    }()

    public lazy var mcvw_feedbackRowTitleLabel: UILabel = { MCCSettingsView.mcvw_chevronRowTitleLabel() }()

    public lazy var mcvw_contactRowTitleLabel: UILabel = { MCCSettingsView.mcvw_chevronRowTitleLabel() }()

    public lazy var mcvw_termsRowTitleLabel: UILabel = { MCCSettingsView.mcvw_chevronRowTitleLabel() }()

    public lazy var mcvw_privacyRowTitleLabel: UILabel = { MCCSettingsView.mcvw_chevronRowTitleLabel() }()

    public lazy var mcvw_userIdValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = MCCSettingsView.mcvw_textSecondary
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .right
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.text = ""
        return l
    }()

    public lazy var mcvw_copyUserIdButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "ic_cm_copy")?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.tintColor = MCCSettingsView.mcvw_textSecondary
        return b
    }()

    public lazy var mcvw_versionLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white.withAlphaComponent(0.24)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    public lazy var mcvw_userIdCard: UIView = {
        self.mcvw_makeUserCard()
    }()

    private lazy var mcvw_feedbackParts: MCEChevronRowParts = {
        self.mcvw_makeChevronRow(assetName: "ic_st_feedback", titleLabel: self.mcvw_feedbackRowTitleLabel)
    }()

    public var mcvw_feedbackRow: UIControl { mcvw_feedbackParts.row }
    public var mcvw_feedbackLeadIconView: UIImageView { mcvw_feedbackParts.lead }
    public var mcvw_feedbackTrailIconView: UIImageView { mcvw_feedbackParts.trail }

    private lazy var mcvw_contactParts: MCEChevronRowParts = {
        self.mcvw_makeChevronRow(assetName: "ic_st_contact", titleLabel: self.mcvw_contactRowTitleLabel)
    }()

    public var mcvw_contactRow: UIControl { mcvw_contactParts.row }
    public var mcvw_contactLeadIconView: UIImageView { mcvw_contactParts.lead }
    public var mcvw_contactTrailIconView: UIImageView { mcvw_contactParts.trail }

    private lazy var mcvw_termsParts: MCEChevronRowParts = {
        self.mcvw_makeChevronRow(assetName: "ic_st_service", titleLabel: self.mcvw_termsRowTitleLabel)
    }()

    public var mcvw_termsRow: UIControl { mcvw_termsParts.row }
    public var mcvw_termsLeadIconView: UIImageView { mcvw_termsParts.lead }
    public var mcvw_termsTrailIconView: UIImageView { mcvw_termsParts.trail }

    private lazy var mcvw_privacyParts: MCEChevronRowParts = {
        self.mcvw_makeChevronRow(assetName: "ic_st_policy", titleLabel: self.mcvw_privacyRowTitleLabel)
    }()

    public var mcvw_privacyRow: UIControl { mcvw_privacyParts.row }
    public var mcvw_privacyLeadIconView: UIImageView { mcvw_privacyParts.lead }
    public var mcvw_privacyTrailIconView: UIImageView { mcvw_privacyParts.trail }

    public lazy var mcvw_feedbackContactCard: UIView = {
        self.mcvw_makeVCard(first: self.mcvw_feedbackRow, second: self.mcvw_contactRow)
    }()

    public lazy var mcvw_legalCard: UIView = {
        self.mcvw_makeVCard(first: self.mcvw_termsRow, second: self.mcvw_privacyRow)
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_scrollView)
        addSubview(mcvw_versionLabel)

        mcvw_versionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-MCEMetric.versionBottomInset)
            make.height.greaterThanOrEqualTo(20)
        }

        mcvw_scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mcvw_versionLabel.snp.top).offset(-MCEMetric.versionScrollGap)
        }

        mcvw_scrollView.addSubview(mcvw_contentStack)
        mcvw_contentStack.snp.makeConstraints { make in
            make.top.equalTo(mcvw_scrollView.contentLayoutGuide.snp.top).offset(MCEMetric.contentTopInset)
            make.leading.equalTo(mcvw_scrollView.frameLayoutGuide.snp.leading)
                .offset(MCEMetric.contentHorizontal)
            make.trailing.equalTo(mcvw_scrollView.frameLayoutGuide.snp.trailing)
                .offset(-MCEMetric.contentHorizontal)
            make.bottom.equalTo(mcvw_scrollView.contentLayoutGuide.snp.bottom)
                .offset(-MCEMetric.contentBottomInset)
        }

        mcvw_contentStack.addArrangedSubview(mcvw_userIdCard)
        mcvw_contentStack.addArrangedSubview(mcvw_feedbackContactCard)
        mcvw_contentStack.addArrangedSubview(mcvw_legalCard)
    }

    private static func mcvw_chevronRowTitleLabel() -> UILabel {
        let t = UILabel()
        t.textColor = MCCSettingsView.mcvw_textPrimary
        t.font = .systemFont(ofSize: 17, weight: .regular)
        return t
    }

    private struct MCEChevronRowParts {
        let row: UIControl
        let lead: UIImageView
        let trail: UIImageView
    }

    private func mcvw_rowAssetIcon(named: String) -> UIImageView {
        let v = UIImageView()
        v.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
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

        let icon = mcvw_rowAssetIcon(named: "ic_st_user")
        mcvw_userIdLeadIconView = icon

        row.addSubview(icon)
        row.addSubview(mcvw_userIdRowTitleLabel)
        row.addSubview(mcvw_userIdValueLabel)
        row.addSubview(mcvw_copyUserIdButton)

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(MCEMetric.iconSize)
        }
        mcvw_userIdRowTitleLabel.snp.makeConstraints { make in
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
            make.leading.greaterThanOrEqualTo(mcvw_userIdRowTitleLabel.snp.trailing).offset(8)
        }

        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        return card
    }

    private func mcvw_makeVCard(first: UIView, second: UIView) -> UIView {
        let card = mcvw_makeCardContainer()
        let sep = UIView()
        sep.backgroundColor = .white.withAlphaComponent(0.06)
        let hairline: CGFloat = 1.0 / max(UIScreen.main.scale, 1)
        sep.snp.makeConstraints { $0.height.equalTo(hairline) }
        let stack = UIStackView(arrangedSubviews: [first, sep, second])
        stack.axis = .vertical
        stack.alignment = .fill
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        return card
    }

    private func mcvw_makeChevronRow(assetName: String, titleLabel: UILabel) -> MCEChevronRowParts {
        let row = UIControl()
        row.snp.makeConstraints { $0.height.equalTo(MCEMetric.rowHeight) }
        let icon = mcvw_rowAssetIcon(named: assetName)
        let chev = UIImageView()
        chev.image = UIImage(named: "ic_cm_arrow")?.withRenderingMode(.alwaysTemplate)
        chev.tintColor = MCCSettingsView.mcvw_textSecondary
        chev.contentMode = .scaleAspectFit
        row.addSubview(icon)
        row.addSubview(titleLabel)
        row.addSubview(chev)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(MCEMetric.iconSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(MCEMetric.titleValueGap)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chev.snp.leading).offset(-8)
        }
        chev.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-MCEMetric.cardInnerHorizontal)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        return MCEChevronRowParts(row: row, lead: icon, trail: chev)
    }

}
