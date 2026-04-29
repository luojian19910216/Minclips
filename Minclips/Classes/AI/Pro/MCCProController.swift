import UIKit
import QuartzCore
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

    public override var transactionStyle: MCETransactionStyle { .bottom }
    
    public override func mcvc_needLeftBarButtonItem() -> Bool { false }
    
    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_cm_close")?.withRenderingMode(.alwaysTemplate),
            target: self,
            action: #selector(mcvc_leftBarButtonItemAction)
        )
        navigationItem.rightBarButtonItem?.tintColor = .white
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

    private func mcvc_reloadProList() {
        let n = mcvc_proListOffers.count
        contentView.mcvw_collectionView.isScrollEnabled = n > 3
        contentView.mcvw_collectionView.reloadData()
    }

    @objc private func mcvc_onCTATapped() {}

    @objc private func mcvc_onRestoreTapped() {}

    @objc private func mcvc_onTermsTapped() {}

    @objc private func mcvc_onPolicyTapped() {}

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
        c.mcvw_setRightLine(leading: "$0.00", trailing: "/" + row.planPeriod.rawValue)
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
