//
//  MCCShopHomeController.swift
//

import UIKit

public class MCCShopHomeController: MCCViewController<MCCBaseView, MCCEmptyViewModel> {
    
    public override func mcvc_configureNav() {
        self.tabBarController?.navigationItem.title = "标题"
        self.tabBarController?.navigationItem.leftBarButtonItem = .init(customView: UIView())
        self.tabBarController?.navigationItem.rightBarButtonItems = [.init(title: "跳转", style: .plain, target: self, action: #selector(mcvc_rightBarButtonItemAction))]
    }
    
    @objc
    public override func mcvc_rightBarButtonItemAction() {
        let vc: MCCViewController = .init()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
