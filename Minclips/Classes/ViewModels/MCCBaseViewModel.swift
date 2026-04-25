//
//  MCCBaseViewModel.swift
//

import Foundation
import Combine

open class MCCBaseViewModel: NSObject {
    
    public var cancellables = Set<AnyCancellable>()
    
    required
    public override init() {
        super.init()
    }
    
}

public final class MCCEmptyViewModel: MCCBaseViewModel {}
