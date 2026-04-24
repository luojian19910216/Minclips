//
//  MCCGuideController.swift
//

import UIKit
import Combine

public class MCCGuideController: MCCViewController<MCCGuideView, MCCGuideViewModel> {
    
    // MARK: - Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel.loadData()
    }
    
    // MARK: - Init
    
    public override func mcvc_setupLocalization() {
        self.contentView.backgroundColor = .black
    }
    
    public override func mcvc_bindService() {
        viewModel.$models
            .sink { [weak self] models in
                self?.contentView.models = models
            }
            .store(in: &cancellables)
    }
    
}
