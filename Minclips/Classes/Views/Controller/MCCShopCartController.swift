//
//  MCCShopCartController.swift
//

import UIKit
import FDFullscreenPopGesture

public class MCCShopCartController: MCCViewController<MCCBaseView, MCCEmptyViewModel> {
    
    public override func mcvc_init() {
        self.fd_prefersNavigationBarHidden = true
    }
    
}
