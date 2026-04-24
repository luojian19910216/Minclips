//
//  MCCBottomSheetController.swift
//

import UIKit
import PanModal

public class MCCBottomSheetController: MCCSheetController<MCCBaseView, MCCEmptyViewModel> {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .orange
    }
            
    public override var longFormHeight: PanModalHeight { .contentHeight(500) }
    
}
