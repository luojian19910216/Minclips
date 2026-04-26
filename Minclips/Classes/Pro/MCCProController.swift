import UIKit
import Common
import FDFullscreenPopGesture

public final class MCCProController: MCCViewController<MCCProView, MCCEmptyViewModel> {

    public override var transactionStyle: MCETransactionStyle { .bottom }
    
    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }

    public override func mcvc_needLeftBarButtonItem() -> Bool {false}

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(mcvc_leftBarButtonItemAction))
    }
    
}
