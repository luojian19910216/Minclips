import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCToolsController: MCCViewController<MCCToolsView, MCCEmptyViewModel> {

    private var mctb_groups: [MCSCfToolboxGroup] = []

    private var mctb_items: [MCSCfToolboxItem] = []

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "0F0F12")!
        contentView.backgroundColor = view.backgroundColor
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let cv = contentView.mctb_collectionView
        cv.dataSource = self
        cv.delegate = self
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mctb_loadStudioToolbox()
    }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        let item = navigationItem
        title = nil
        item.title = nil
        item.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        item.leftBarButtonItem = MCCRootTabNavChrome.leftTitleBarButtonItem(
            title: "Studio",
            textColor: .white
        )
        item.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
    }

}

extension MCCToolsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mctb_items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCToolTextCell.mctb_id,
            for: indexPath
        ) as! MCCToolTextCell
        let item = mctb_items[indexPath.item]
        cell.mctb_textLabel.text = item.code
        cell.mctb_textLabel.textColor = .white
        cell.mctb_textLabel.font = .systemFont(ofSize: 12, weight: .regular)
        cell.contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        mctb_itemSize(in: collectionView)
    }

}

private extension MCCToolsController {

    func mctb_loadStudioToolbox() {
        MCCCfAPIManager.shared.studioToolbox()
            .asLoadState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                if let m = s.model, !s.isLoading {
                    self.mctb_groups = m.items
                    self.mctb_items = self.mctb_groups.first?.item ?? []
                } else if s.error != nil {
                    self.mctb_groups = []
                    self.mctb_items = []
                }
                self.contentView.mctb_collectionView.reloadData()
            }
            .store(in: &cancellables)
    }

    func mctb_itemSize(in collectionView: UICollectionView) -> CGSize {
        let sideInset: CGFloat = 32
        let w = max(0, collectionView.bounds.width - sideInset)
        return CGSize(width: w, height: 300)
    }

}
