//
//  MCCLaunchController.swift
//

import UIKit

public class MCCLaunchController: MCCViewController<MCCLaunchView, MCCEmptyViewModel> {
    
    // MARK: - Init
    
    public override func mcvc_setupLocalization() {
        self.contentView.backgroundColor = .black
    }
    
}
