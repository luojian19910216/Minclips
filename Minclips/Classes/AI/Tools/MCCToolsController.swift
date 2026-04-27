import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCToolsController: MCCViewController<MCCToolsView, MCCEmptyViewModel> {

    private var mcvc_groups: [MCSCfToolboxGroup] = []

    private var mcvc_items: [MCSCfToolboxItem] {
        mcvc_groups.flatMap { $0.item }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        self.tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Studio")

        self.tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
    }

    @objc public func mcvc_onProTapped() {
        let vc: MCCProController = .init()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "0F0F12")!
        contentView.backgroundColor = view.backgroundColor
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mcvw_collectionView
        cv.dataSource = self
        cv.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcvc_loadStudioToolbox()
    }

    private func mcvc_loadStudioToolbox() {
        MCCCfAPIManager.shared.studioToolbox()
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                self.contentView.mcvw_setListSkeletonVisible(s.isLoading && self.mcvc_items.isEmpty)
                if let m = s.model, !s.isLoading {
                    self.mcvc_groups = m.items
                } else if s.error != nil {
                    self.mcvc_groups = []
                }
                self.contentView.mcvw_collectionView.reloadData()
            }
            .store(in: &cancellables)
    }

}

extension MCCToolsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCToolCardCell.mcvw_id,
            for: indexPath
        ) as! MCCToolCardCell
        guard let item = mcvc_items[safe: indexPath.item] else { return cell }
        cell.mcvw_apply(code: item.code, title: item.title, iconContent: item.iconContent)
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        mcvc_itemSize(in: collectionView)
    }

}

private extension MCCToolsController {

    func mcvc_itemSize(in collectionView: UICollectionView) -> CGSize {
        guard let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: collectionView.bounds.width, height: 128)
        }

        let w = collectionView.bounds.width - flow.sectionInset.left - flow.sectionInset.right
        return CGSize(width: max(0, w), height: 128)
    }

}

private extension Array {

    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

}
