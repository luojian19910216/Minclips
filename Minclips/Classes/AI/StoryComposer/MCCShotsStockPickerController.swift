import UIKit
import Common
public final class MCCShotsStockPickerController: MCCViewController<MCCShotsStockPickerView, MCCEmptyViewModel> {

    private var mcvc_selected: Set<Int> = [1]

    private let mcvc_placeholderTimes = ["00:05", "01:12", "03:40", "00:07", "00:42", "00:06", "00:58", "00:06", "09:12"]

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "0F0F12")
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let v = contentView
        v.mcvw_closeButton.addTarget(self, action: #selector(mcvc_close), for: .touchUpInside)
        v.mcvw_collectionView.dataSource = self
        v.mcvw_collectionView.delegate = self
    }

    @objc
    private func mcvc_close() {
        dismiss(animated: true)
    }

    private func mcvc_itemSize(containerWidth w: CGFloat) -> CGSize {
        let inset = MCCShotsStockPickerView.mcvw_horizontalInset * 2
        let gutters = MCCShotsStockPickerView.mcvw_gridGutterValue * 2
        let colW = floor((w - inset - gutters) / 3)
        let h = colW * 160 / 120
        return CGSize(width: colW, height: h)
    }
}

extension MCCShotsStockPickerController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1 + mcvc_placeholderTimes.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCShotsStockPickerCell.mcvw_reuseId,
            for: indexPath
        ) as! MCCShotsStockPickerCell
        if indexPath.item == 0 {
            cell.mcvw_configureOwnPrompt()
        } else {
            let t = mcvc_placeholderTimes[indexPath.item - 1]
            cell.mcvw_configureThumbnail(timeText: t)
        }
        cell.mcvw_applyBadge(selected: mcvc_selected.contains(indexPath.item))
        return cell
    }
}

extension MCCShotsStockPickerController: UICollectionViewDelegateFlowLayout {

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        mcvc_itemSize(containerWidth: collectionView.bounds.width)
    }
}

extension MCCShotsStockPickerController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if mcvc_selected.contains(indexPath.item) {
            mcvc_selected.remove(indexPath.item)
        } else {
            mcvc_selected.insert(indexPath.item)
        }
        collectionView.reloadItems(at: [indexPath])
    }
}
