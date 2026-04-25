//
//  MCCCfViewModel.swift
//

import Foundation
import Data
import Common
import Combine

public final class MCCCfViewModel: MCCBaseViewModel {
    
    @Published public var state = MCSLoadState<MCSCfLauncherResponse>()
    
    public func loadData() {
        MCCCfAPIManager.shared.launcher()
            .asLoadState()
            .assign(to: &$state)
    }
    
}
