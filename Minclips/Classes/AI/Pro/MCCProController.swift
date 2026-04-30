import UIKit
import SafariServices
import QuartzCore
import StoreKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCProController: MCCViewController<MCCProView, MCCEmptyViewModel> {

    private static let mcvc_proOfferCategory = "vip_scene_two"

    private var mcvc_lastCatalog: MCSSubscriptionCatalogResponse?

    private var mcvc_proListOffers: [MCSSubscriptionRow] = []

    private var mcvc_selectedOfferIndex: Int = 1

    /// 目录接口可能从缓存**同一 run loop**内就回调，会抢在首帧布局前关掉骨架，看起来像「再也不出来」。用下次 run + 最短展示时间兜底。
    private static let mcvc_proSkeletonMinDisplay: TimeInterval = 0.15
    private var mcvc_proSkeletonShownAt: CFTimeInterval?

    private var mcvc_storeKitLocalizedPriceByProductId: [String: String] = [:]

    private var mcvc_storeKitProductsByProductId: [String: Product] = [:]

    private var mcvc_subscriptionPipelineBusy = false

    public override var transactionStyle: MCETransactionStyle { .bottom }
    
    public override func mcvc_needLeftBarButtonItem() -> Bool { false }
    
    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        navigationItem.leftBarButtonItem = nil
        navigationItem.setHidesBackButton(true, animated: false)
        
        navigationItem.rightBarButtonItem = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_cm_close")?.withRenderingMode(.alwaysTemplate),
            target: self,
            action: #selector(mcvc_leftBarButtonItemAction)
        )
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let bg = UIColor.black
        view.backgroundColor = bg
        contentView.backgroundColor = bg
        let v = contentView
        v.mcvw_headlineLabel.text = ""
        v.mcvw_subheadlineLabel.text = ""
        v.mcvw_renewalHintLabel.text = "Auto renews, cancel anytime"
        v.mcvw_ctaButton.setTitle("Subscription", for: .normal)
        v.mcvw_restoreButton.setTitle("Restore", for: .normal)
        v.mcvw_termsButton.setTitle("Terms", for: .normal)
        v.mcvw_policyButton.setTitle("Policy", for: .normal)
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let v = contentView
        v.mcvw_ctaButton.addTarget(self, action: #selector(mcvc_onCTATapped), for: .touchUpInside)
        v.mcvw_restoreButton.addTarget(self, action: #selector(mcvc_onRestoreTapped), for: .touchUpInside)
        v.mcvw_termsButton.addTarget(self, action: #selector(mcvc_onTermsTapped), for: .touchUpInside)
        v.mcvw_policyButton.addTarget(self, action: #selector(mcvc_onPolicyTapped), for: .touchUpInside)
        v.mcvw_collectionView.dataSource = self
        v.mcvw_collectionView.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcvc_proSkeletonShownAt = CACurrentMediaTime()
        contentView.mcvw_setProSkeletonVisible(true)
        mcvc_loadSubscriptionCatalog()
        mcvc_reloadProList()
    }

    private func mcvc_loadSubscriptionCatalog() {
        MCCSubscriptionAPIManager.shared.fetchSubscriptionCatalog()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.mcvc_applyCatalogForUI(nil)
                }
            } receiveValue: { [weak self] r in
                self?.mcvc_applyCatalogForUI(r)
            }
            .store(in: &cancellables)
    }

    private func mcvc_applyCatalogForUI(_ r: MCSSubscriptionCatalogResponse?) {
        if MCCNetworkConfig.shared.channel == .develop {
            mcvc_storeKitLocalizedPriceByProductId = [:]
            mcvc_storeKitProductsByProductId = [:]
        }
        mcvc_lastCatalog = r
        let list = r?.offers.filter { $0.offerCategory == Self.mcvc_proOfferCategory } ?? []
        mcvc_proListOffers = Array(list.reversed())
        if list.isEmpty {
            mcvc_selectedOfferIndex = 0
        } else {
            mcvc_selectedOfferIndex = min(1, list.count - 1)
        }
        mcvc_applyBackFeatureTitles()
        mcvc_applyCTATitle()
        mcvc_reloadProList()
        mcvc_refreshStoreKitPricesIfNeeded()
        let shownAt = mcvc_proSkeletonShownAt
        mcvc_proSkeletonShownAt = nil
        let minDelay: TimeInterval
        if let shownAt {
            minDelay = max(0, Self.mcvc_proSkeletonMinDisplay - (CACurrentMediaTime() - shownAt))
        } else {
            minDelay = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + minDelay) { [weak self] in
            self?.contentView.mcvw_setProSkeletonVisible(false)
        }
    }

    private func mcvc_applyBackFeatureTitles() {
        let v = contentView
        guard mcvc_proListOffers.indices.contains(mcvc_selectedOfferIndex) else {
            v.mcvw_headlineLabel.text = ""
            v.mcvw_subheadlineLabel.text = ""
            return
        }
        let lines = mcvc_proListOffers[mcvc_selectedOfferIndex].backFeatureLines
        v.mcvw_headlineLabel.text = lines.indices.contains(0) ? lines[0].line : ""
        v.mcvw_subheadlineLabel.text = lines.indices.contains(1) ? lines[1].line : ""
    }

    private func mcvc_applyCTATitle() {
        let v = contentView
        let b = v.mcvw_ctaButton
        let fallback = "Subscription"
        let title: String
        if mcvc_proListOffers.indices.contains(mcvc_selectedOfferIndex) {
            let row = mcvc_proListOffers[mcvc_selectedOfferIndex]
            let pitch = row.savingsPitch.trimmingCharacters(in: .whitespacesAndNewlines)
            if !pitch.isEmpty {
                title = pitch + " now"
            } else {
                let cta = row.callToAction.trimmingCharacters(in: .whitespacesAndNewlines)
                title = cta.isEmpty ? fallback : cta
            }
        } else {
            title = fallback
        }
        UIView.performWithoutAnimation {
            b.setTitle(title, for: .normal)
            b.titleLabel?.layoutIfNeeded()
            b.layoutIfNeeded()
        }
    }

    private func mcvc_refreshStoreKitPricesIfNeeded() {
        guard MCCNetworkConfig.shared.channel == .isolation else { return }
        let ids = Set(
            mcvc_proListOffers
                .map { $0.offerId.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        guard !ids.isEmpty else {
            mcvc_storeKitLocalizedPriceByProductId = [:]
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                let products = try await Product.products(for: Array(ids))
                var nextPrices: [String: String] = [:]
                var nextProducts: [String: Product] = [:]
                for p in products {
                    nextPrices[p.id] = p.displayPrice
                    nextProducts[p.id] = p
                }
                await MainActor.run {
                    self.mcvc_storeKitLocalizedPriceByProductId = nextPrices
                    self.mcvc_storeKitProductsByProductId = nextProducts
                    self.mcvc_reloadProList()
                }
            } catch {
                await MainActor.run {
                    self.mcvc_storeKitLocalizedPriceByProductId = [:]
                    self.mcvc_storeKitProductsByProductId = [:]
                    self.mcvc_reloadProList()
                }
            }
        }
    }

    private func mcvc_reloadProList() {
        let n = mcvc_proListOffers.count
        contentView.mcvw_collectionView.isScrollEnabled = n > 3
        contentView.mcvw_collectionView.reloadData()
    }

    /// Isolation 下列表价仅来自 StoreKit；未拉到 `displayPrice` 时占位，不回落目录价。
    private static let mcvc_proStoreKitPricePlaceholder = "-.--"

    private func mcvc_proPlanPriceLeading(from row: MCSSubscriptionRow) -> String {
        if MCCNetworkConfig.shared.channel == .develop {
            return mcvc_proPlanPriceLeadingFromCatalog(from: row)
        }
        let pid = row.offerId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pid.isEmpty else { return Self.mcvc_proStoreKitPricePlaceholder }
        let localized = mcvc_storeKitLocalizedPriceByProductId[pid]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !localized.isEmpty {
            return localized
        }
        return Self.mcvc_proStoreKitPricePlaceholder
    }

    private func mcvc_proPlanPriceLeadingFromCatalog(from row: MCSSubscriptionRow) -> String {
        let sign = row.currencySign.trimmingCharacters(in: .whitespacesAndNewlines)
        let current = row.currentPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        if !current.isEmpty {
            return mcvc_proCatalogPriceAppendingCurrencySignIfNeeded(current, sign: sign)
        }
        let headline = row.priceHeadline.trimmingCharacters(in: .whitespacesAndNewlines)
        if !headline.isEmpty {
            return mcvc_proCatalogPriceAppendingCurrencySignIfNeeded(headline, sign: sign)
        }
        let list = row.listPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        if !list.isEmpty {
            return mcvc_proCatalogPriceAppendingCurrencySignIfNeeded(list, sign: sign)
        }
        let line = row.priceLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if !line.isEmpty {
            return mcvc_proCatalogPriceAppendingCurrencySignIfNeeded(line, sign: sign)
        }
        return "—"
    }

    /// Catalog often returns `currentPrice` as a bare number; `currencySign` is the unit (e.g. `$`, `¥`).
    private func mcvc_proCatalogPriceAppendingCurrencySignIfNeeded(_ value: String, sign: String) -> String {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = sign.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return v }
        guard !s.isEmpty else { return v }
        if v.hasPrefix(s) { return v }
        if let first = v.unicodeScalars.first, mcvc_proUnicodeScalarLikelyCurrencySymbol(first) {
            return v
        }
        if v.hasPrefix("US$") || v.hasPrefix("HK$") || v.hasPrefix("NT$") {
            return v
        }
        guard mcvc_proCatalogStringLooksLikePlainNumericAmount(v) else { return v }
        return s + v
    }

    private func mcvc_proCatalogStringLooksLikePlainNumericAmount(_ v: String) -> Bool {
        v.range(of: "^[0-9]+([.,][0-9]+)?$", options: .regularExpression) != nil
    }

    private func mcvc_proUnicodeScalarLikelyCurrencySymbol(_ scalar: Unicode.Scalar) -> Bool {
        let code = scalar.value
        switch code {
        case 0x0024: return true
        case 0x00A2...0x00A5: return true
        case 0x058F: return true
        case 0x060B: return true
        case 0x09F2...0x09F3: return true
        case 0x0AF1: return true
        case 0x0BF9: return true
        case 0x0E3F: return true
        case 0x17DB: return true
        case 0x20A0...0x20C0: return true
        case 0xA838: return true
        case 0xFDFC: return true
        case 0xFE69, 0xFF04, 0xFFE0...0xFFE6: return true
        case 0x11FDD...0x11FE0: return true
        default: return false
        }
    }

    @MainActor
    private func mcvc_runPurchasePipeline() async {
        guard !mcvc_subscriptionPipelineBusy else { return }
        guard mcvc_proListOffers.indices.contains(mcvc_selectedOfferIndex) else { return }
        let pid = mcvc_proListOffers[mcvc_selectedOfferIndex].offerId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pid.isEmpty else {
            MCCToastManager.showToast("Plan unavailable.", in: view)
            return
        }
        mcvc_subscriptionPipelineBusy = true
        mcvc_applySubscriptionChromeBusy(true)
        MCCToastManager.showHUD(in: view)
        defer {
            mcvc_subscriptionPipelineBusy = false
            mcvc_applySubscriptionChromeBusy(false)
        }
        switch await MCCStoreKitSubscription.purchase(productId: pid) {
        case .success(.activated):
            MCCToastManager.showToast("Subscription activated.", in: view)
            mcvc_popIfMembershipActive()
        case .success(.userCancelled):
            MCCToastManager.hide()
        case .success(.pendingApproval):
            MCCToastManager.showToast("Purchase is pending approval.", in: view)
        case .success(.unrecognizedPurchaseResult):
            MCCToastManager.hide()
        case .failure(let err):
            MCCToastManager.showToast(err.userFacingMessage, in: view)
        }
    }

    @MainActor
    private func mcvc_runRestorePipeline() async {
        guard !mcvc_subscriptionPipelineBusy else { return }
        mcvc_subscriptionPipelineBusy = true
        mcvc_applySubscriptionChromeBusy(true)
        MCCToastManager.showHUD(in: view)
        defer {
            mcvc_subscriptionPipelineBusy = false
            mcvc_applySubscriptionChromeBusy(false)
        }
        let catalogIds = Set(
            mcvc_proListOffers.map { $0.offerId.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        )
        let filterIds: Set<String>? = {
            let s = catalogIds
            return s.isEmpty ? nil : s
        }()
        switch await MCCStoreKitSubscription.restorePurchases(filterProductIds: filterIds) {
        case .success(let n):
            if n > 0 {
                MCCToastManager.showToast("Purchases restored.", in: view)
                mcvc_popIfMembershipActive()
            } else {
                MCCToastManager.showToast("No purchases to restore.", in: view)
            }
        case .failure(let err):
            MCCToastManager.showToast(err.userFacingMessage, in: view)
        }
    }

    private func mcvc_applySubscriptionChromeBusy(_ busy: Bool) {
        contentView.mcvw_ctaButton.isUserInteractionEnabled = !busy
        contentView.mcvw_restoreButton.isUserInteractionEnabled = !busy
    }

    private func mcvc_popIfMembershipActive() {
        if MCCAccountService.shared.currentUser.value?.membershipActive == true {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func mcvc_onCTATapped() {
        Task { @MainActor in
            await mcvc_runPurchasePipeline()
        }
    }

    @objc private func mcvc_onRestoreTapped() {
        Task { @MainActor in
            await mcvc_runRestorePipeline()
        }
    }

    @objc private func mcvc_onTermsTapped() {
        guard let url = URL(string: MCCAppConfig.shared.service) else {return}
        self.present(SFSafariViewController(url: url), animated: true)
    }

    @objc private func mcvc_onPolicyTapped() {
        guard let url = URL(string: MCCAppConfig.shared.policy) else {return}
        self.present(SFSafariViewController(url: url), animated: true)
    }

}


extension MCCProController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_proListOffers.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: MCCProPlanCell.mcvw_id, for: indexPath) as! MCCProPlanCell
        c.mcvw_setSelection(indexPath.item == mcvc_selectedOfferIndex)
        let row = mcvc_proListOffers[indexPath.item]
        c.mcvw_titleLabel.text = row.displayName
        c.mcvw_setRightLine(leading: mcvc_proPlanPriceLeading(from: row), trailing: "/" + row.planPeriod.rawValue)
        let corner = row.cornerBadge.trimmingCharacters(in: .whitespacesAndNewlines)
        if corner.isEmpty {
            c.mcvw_popularPill.isHidden = true
        } else {
            c.mcvw_popularPill.setTitle(corner, for: .normal)
            c.mcvw_popularPill.isHidden = false
        }
        let pitch = row.savingsPitch.trimmingCharacters(in: .whitespacesAndNewlines)
        if pitch.isEmpty {
            c.mcvw_saveBadge.isHidden = true
        } else {
            c.mcvw_saveBadge.setTitle(pitch, for: .normal)
            c.mcvw_saveBadge.isHidden = false
        }
        return c
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let w = max(
            0,
            collectionView.bounds.width
                - MCCProView.mcvw_listHorizontal * 2
        )
        return CGSize(width: w, height: MCCProView.mcvw_listCellHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == mcvc_selectedOfferIndex { return }
        let previous = mcvc_selectedOfferIndex
        mcvc_selectedOfferIndex = indexPath.item
        var paths = [indexPath]
        if (0..<mcvc_proListOffers.count).contains(previous) {
            paths.append(IndexPath(item: previous, section: 0))
        }
        UIView.performWithoutAnimation {
            mcvc_applyBackFeatureTitles()
            mcvc_applyCTATitle()
            collectionView.reloadItems(at: paths)
        }
    }

}
