import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data
import SafariServices

public final class MCCSettingsController: MCCViewController<MCCSettingsView, MCCEmptyViewModel> {

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        self.navigationItem.title = "Settings"
    }
    
    public override func mcvc_loadData() {
        super.mcvc_loadData()
        
        let short = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
        contentView.mcvw_setVersionText("V\(short)")
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
                self?.contentView.mcvw_setUserIdDisplay(text)
            }
            .store(in: &cancellables)

        contentView.mcvw_onCopyUserId = { [weak self] in
            self?.mcvc_copyUserIdToPasteboard()
        }
        
        contentView.mcvw_onFeedback = { [weak self] in
            self?.mcvc_openSafariIfPresent(MCVCSettingsURL.feedback)
        }
        
        contentView.mcvw_onContact = { [weak self] in
            self?.mcvc_openContactMail()
        }
        
        contentView.mcvw_onTerms = { [weak self] in
            self?.mcvc_openSafariIfPresent(MCVCSettingsURL.termsOfService)
        }
        
        contentView.mcvw_onPrivacy = { [weak self] in
            self?.mcvc_openSafariIfPresent(MCVCSettingsURL.privacyPolicy)
        }
    }

    private func mcvc_copyUserIdToPasteboard() {
        var text = (MCCAccountService.shared.currentUser.value?.userId).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        } ?? ""
        if text.isEmpty { text = MCCKeychainManager.shared.deviceId }
        UIPasteboard.general.string = text
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
