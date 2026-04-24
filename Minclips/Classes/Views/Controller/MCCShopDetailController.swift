//
//  MCCShopDetailController.swift
//

import UIKit
import PanModal

public class MCCShopDetailController: MCCViewController<MCCBaseView, MCCEmptyViewModel> {
    
    @objc
    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        self.navigationItem.title = "标题"
        self.navigationItem.rightBarButtonItems = [.init(title: "跳转", style: .plain, target: self, action: #selector(mcvc_rightBarButtonItemAction))]
    }
    
    @objc
    public override func mcvc_rightBarButtonItemAction() {
        let vc: MCCSheetController = .init()
        self.present(vc, animated: true)
//        let vc: MCCPresentController = .init()
//        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    public override func mcvc_setupLocalization() {
        self.view.backgroundColor = .red
    }
    
}
