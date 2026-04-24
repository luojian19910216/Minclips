//
//  MCCConfigViewModel.swift
//

import Foundation
import Data
import Common
import Combine

public final class MCCConfigViewModel: MCCBaseViewModel {
    
    @Published public var state = MCSLoadState<MCSConfigAppResponse>()
    
    public func loadData() {
        MCCConfigAPIManager.shared.appConfig()
            .asLoadState()
            .assign(to: &$state)
    }
    
}
