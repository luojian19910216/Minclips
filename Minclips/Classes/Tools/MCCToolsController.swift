import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCToolsController: MCCViewController<MCCToolsView, MCCEmptyViewModel> {

    private var mcvc_groups: [MCSCfToolboxGroup] = []

    private var mcvc_items: [MCSCfToolboxItem] = []

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        self.tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(
            title: "Studio",
            textColor: .white
        )
        
        self.tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
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

}

extension MCCToolsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mcvc_items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCToolTextCell.mcvw_id,
            for: indexPath
        ) as! MCCToolTextCell
        let item = mcvc_items[indexPath.item]
        cell.mcvw_textLabel.text = item.code
        cell.mcvw_textLabel.textColor = UIColor.white
        cell.mcvw_textLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        cell.contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
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

    func mcvc_loadStudioToolbox() {
        MCCCfAPIManager.shared.studioToolbox()
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                if let m = s.model, !s.isLoading {
                    self.mcvc_groups = m.items
                    self.mcvc_items = self.mcvc_groups.first?.item ?? []
                } else if s.error != nil {
                    self.mcvc_groups = []
                    self.mcvc_items = []
                }
                self.contentView.mcvw_collectionView.reloadData()
            }
            .store(in: &cancellables)
    }

    func mcvc_itemSize(in collectionView: UICollectionView) -> CGSize {
        guard let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 100, height: 120)
        }

        let inset = flow.sectionInset

        let spacing = flow.minimumInteritemSpacing

        let inner = collectionView.bounds.width - inset.left - inset.right - spacing

        let colW = max(0, floor(inner / 2))
        return CGSize(width: colW, height: 120)
    }

}
