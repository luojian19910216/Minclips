import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCProController: MCCViewController<MCCProView, MCCEmptyViewModel> {

    private static let mcvc_proOfferCategory = "vip_scene_two"

    private var mcvc_lastCatalog: MCSSubscriptionCatalogResponse?

    private var mcvc_proListOffers: [MCSSubscriptionRow] = []

    private var mcvc_selectedOfferIndex: Int = 0

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override var transactionStyle: MCETransactionStyle { .bottom }

    public override func mcvc_init() {
        super.mcvc_init()
        fd_prefersNavigationBarHidden = false
    }

    public override func mcvc_needLeftBarButtonItem() -> Bool { false }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_shadowHidden = true
        nav.navigationBar.mc_barStyle = .transparentLight
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        navigationItem.title = nil
        let img = ["multiply", "xmark"]
            .compactMap { UIImage(systemName: $0)?.withRenderingMode(.alwaysTemplate) }
            .first
        if let img {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: img,
                style: .plain,
                target: self,
                action: #selector(mcvc_leftBarButtonItemAction)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "\u{2715}",
                style: .plain,
                target: self,
                action: #selector(mcvc_leftBarButtonItemAction)
            )
        }
        navigationItem.rightBarButtonItem?.tintColor = .white
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let bg = UIColor.black
        view.backgroundColor = bg
        contentView.backgroundColor = bg
        let v = contentView
        v.mcvw_headlineLabel.text = "UNLOCK ALL AI VIDEOS & IMAGES"
        v.mcvw_subheadlineLabel.text = "500 credits per week, total 26000 & High-Speed Generation Queue."
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
        mcvc_proListOffers = list
        if mcvc_selectedOfferIndex >= list.count {
            mcvc_selectedOfferIndex = max(0, list.count - 1)
        }
        mcvc_reloadProList()
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
        let isFirst = indexPath.item == 0
        c.mcvw_setSelection(indexPath.item == mcvc_selectedOfferIndex)
        c.mcvw_titleLabel.text = "—"
        c.mcvw_setRightLine(leading: "—", trailing: "")
        if isFirst {
            c.mcvw_popularPill.text = " Popular "
            c.mcvw_popularPill.isHidden = false
            c.mcvw_saveBadge.setTitle(" Save 85% ", for: .normal)
            c.mcvw_saveBadge.isHidden = false
        } else {
            c.mcvw_popularPill.isHidden = true
            c.mcvw_saveBadge.isHidden = true
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
        mcvc_selectedOfferIndex = indexPath.item
        collectionView.reloadData()
    }

}
