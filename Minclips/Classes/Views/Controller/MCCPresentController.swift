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
    }
    
    public override func mcvc_setupLocalization() {
        self.view.backgroundColor = .orange
    }
    
}
