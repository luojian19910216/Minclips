//
//  MCCPresentController.swift
//

import UIKit

public class MCCPresentController: MCCViewController<MCCBaseView, MCCEmptyViewModel> {
    
    public override var transactionStyle: MCETransactionStyle { .bottom }

    @objc
    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        self.navigationItem.title = "标题"
        self.navigationItem.rightBarButtonItems = [.init(title: "跳转", style: .plain, target: self, action: #selector(mcvc_rightBarButtonItemAction))]
    }
    
    @objc
    public override func mcvc_rightBarButtonItemAction() {
        let vc: MCCShopDetailController = .init()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    public override func mcvc_setupLocalization() {
        self.view.backgroundColor = .orange
    }
    
}
