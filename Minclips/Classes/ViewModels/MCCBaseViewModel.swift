//
//  MCCBaseViewModel.swift
//

import Foundation
import Combine

open class MCCBaseViewModel: NSObject {
    
    // MARK: - Properties
    
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - Life Cycle
    
    required
    public override init() {
        super.init()
    }
    
}

public final class MCCEmptyViewModel: MCCBaseViewModel {}
