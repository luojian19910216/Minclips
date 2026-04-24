//
//  MCCUserHomeController.swift
//

import UIKit

public class MCCUserHomeController: MCCViewController<MCCBaseView, MCCEmptyViewModel> {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .red
    }
    
    public override func mcvc_configureNav() {
        self.tabBarController?.navigationItem.title = "标题"
        self.tabBarController?.navigationItem.leftBarButtonItem = .init(customView: UIView())
        self.tabBarController?.navigationItem.rightBarButtonItems = [.init(title: "跳转", style: .plain, target: self, action: #selector(mcvc_rightBarButtonItemAction))]
    }
    
    @objc
    public override func mcvc_rightBarButtonItemAction() {
//        let vc: MCCShopDetailController = .init()
//        self.navigationController?.pushViewController(vc, animated: true)
        
//        let vc: MCCTopPopController = .init()
//        self.present(vc, animated: true)
        
        let vc: MCCEaseInPopController = .init()
        self.present(vc, animated: true)
        
//        let vc = MCCAlertManager.alert(title: "标题", message: "描述阿萨德哈克", confirmBtnTitle: "确认", cancelBtnTitle: "取消")
//        self.present(vc, animated: true)
                
//        MCCToastManager.showHUD(in: self.view)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5000)) {
//            MCCToastManager.showToast("success", in: self.view)
//        }
    }
    
}
