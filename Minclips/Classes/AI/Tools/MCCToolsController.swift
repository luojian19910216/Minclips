import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import MJRefresh
import Data

public final class MCCToolsController: MCCViewController<MCCToolsView, MCCEmptyViewModel> {

    private var mcvc_groups: [MCSCfToolboxGroup] = []

    private var mcvc_toolboxCancellable: AnyCancellable?

    private var mcvc_items: [MCSCfToolboxItem] {
        mcvc_groups.flatMap { $0.item }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        self.tabBarController?.navigationItem.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Studio")

        self.tabBarController?.navigationItem.rightBarButtonItem = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_nav_pro"),
            title: "PRO",
            target: self,
            action: #selector(mcvc_onProTapped)
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
        cv.allowsSelection = true

        let header = MJRefreshNormalHeader { [weak self] in
            self?.mcvc_loadStudioToolbox()
        }
        header.lastUpdatedTimeLabel?.isHidden = true
        cv.mj_header = header
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcvc_loadStudioToolbox()
    }

    private func mcvc_loadStudioToolbox() {
        mcvc_toolboxCancellable?.cancel()
        mcvc_toolboxCancellable = MCCCfAPIManager.shared.studioToolbox()
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
                if !s.isLoading {
                    self.contentView.mcvw_collectionView.mj_header?.endRefreshing()
                }
            }
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

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let nav = navigationController else { return }

        switch indexPath.item {
        case 0:
            nav.pushViewController(MCCStoryClipsComposerController(), animated: true)
        case 1:
            nav.pushViewController(MCCCreatePromptFlowController(kind: .character), animated: true)
        case 2:
            nav.pushViewController(MCCCreatePromptFlowController(kind: .shot), animated: true)
        default:
            break
        }
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
