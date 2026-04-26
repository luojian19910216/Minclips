import UIKit
import Common
import FDFullscreenPopGesture

public final class MCCProController: MCCViewController<MCCProView, MCCEmptyViewModel> {
    
    public override var transactionStyle: MCETransactionStyle { .bottom }
    
    public override func mcvc_needLeftBarButtonItem() -> Bool {false}

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.rightBarButtonItem = mcc_closeBarButtonItem()
    }

    private func mcc_closeBarButtonItem() -> UIBarButtonItem {
        let img = ["multiply", "xmark"]
            .compactMap { UIImage(systemName: $0)?.withRenderingMode(.alwaysTemplate) }
            .first
        let item: UIBarButtonItem
        if let img {
            item = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(mcvc_leftBarButtonItemAction))
        } else {
            item = UIBarButtonItem(title: "\u{2715}", style: .plain, target: self, action: #selector(mcvc_leftBarButtonItemAction))
        }
        item.tintColor = .white
        return item
    }
}
