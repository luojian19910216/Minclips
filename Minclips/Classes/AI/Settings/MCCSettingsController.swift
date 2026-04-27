import UIKit
import Common
import Combine
import CombineCocoa
import FDFullscreenPopGesture
import Data
import SafariServices

public final class MCCSettingsController: MCCViewController<MCCSettingsView, MCCEmptyViewModel> {

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        self.navigationItem.title = "Settings"
    }

    public override func mcvc_setupLocalization() {
        let v = contentView
        v.mcvw_userIdRowTitleLabel.text = "User ID"
        v.mcvw_feedbackRowTitleLabel.text = "Feedback"
        v.mcvw_contactRowTitleLabel.text = "Contact Us"
        v.mcvw_termsRowTitleLabel.text = "Terms of Service"
        v.mcvw_privacyRowTitleLabel.text = "Privacy Policy"
    }

    public override func mcvc_loadData() {
        let short = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
        contentView.mcvw_versionLabel.text = "V\(short)"
    }

    public override func mcvc_bind() {
        super.mcvc_bind()

        MCCAccountService.shared.currentUser
            .map { u -> String in
                let id = u?.userId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !id.isEmpty { return id }
                return MCCKeychainManager.shared.deviceId
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.contentView.mcvw_userIdValueLabel.text = text
            }
            .store(in: &cancellables)

        let v = contentView
        let userIdValueTap = UITapGestureRecognizer()
        v.mcvw_userIdValueLabel.addGestureRecognizer(userIdValueTap)
        v.mcvw_userIdValueLabel.isUserInteractionEnabled = true
        Publishers.Merge(
            v.mcvw_copyUserIdButton.controlEventPublisher(for: .touchUpInside),
            userIdValueTap.tapPublisher.map { _ in }
        )
        .sink { [weak self] in
            self?.mcvc_copyUserIdToPasteboard()
        }
        .store(in: &cancellables)

        v.mcvw_feedbackRow.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in self?.mcvc_openSafariIfPresent(MCVCSettingsURL.feedback) }
            .store(in: &cancellables)
        v.mcvw_contactRow.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in self?.mcvc_openContactMail() }
            .store(in: &cancellables)
        v.mcvw_termsRow.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in self?.mcvc_openSafariIfPresent(MCVCSettingsURL.termsOfService) }
            .store(in: &cancellables)
        v.mcvw_privacyRow.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in self?.mcvc_openSafariIfPresent(MCVCSettingsURL.privacyPolicy) }
            .store(in: &cancellables)
    }

    private func mcvc_copyUserIdToPasteboard() {
        guard let userId = MCCAccountService.shared.currentUser.value?.userId else {return}
        UIPasteboard.general.string = userId
        MCCToastManager.showToast("Copied", in: view)
    }

    private func mcvc_openContactMail() {
        guard let url = URL(string: "mailto:support@miniclips.com?subject=Minclips") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func mcvc_openSafariIfPresent(_ url: URL?) {
        guard let url else { return }
        let sf = SFSafariViewController(url: url)
        sf.preferredControlTintColor = .white
        present(sf, animated: true)
    }

}

private enum MCVCSettingsURL {
    static let termsOfService: URL? = nil
    static let privacyPolicy: URL? = nil
    static let feedback: URL? = nil
}
