import Foundation
import Combine
import CombineExt

public enum MCEAppState {
    case launch, guide, main

}

public final class MCCAppStateStore {
    
    public static let shared: MCCAppStateStore = .init()
    
    @Published public private(set) var appState: MCEAppState = .launch
    
    private var cancellables = Set<AnyCancellable>()

    private init() {
        [
            MCCAppConfig.shared.$networkStatus.eraseToAnyPublisher(),
            MCCAppConfig.shared.$apnsStatus.eraseToAnyPublisher(),
            MCCAppConfig.shared.$attStatus.eraseToAnyPublisher(),
            MCCAppConfig.shared.$loginStatus.eraseToAnyPublisher(),
            MCCAppConfig.shared.$configStatus.eraseToAnyPublisher(),
            MCCAppConfig.shared.$guideFlag.eraseToAnyPublisher()
        ]
            .combineLatest()
            .map { values -> MCEAppState in
                guard values.count == 6 else { return .launch }
                let (networkStatus, apnsStatus, attStatus, loginStatus, configStatus, guideFlag) = (
                    values[0], values[1], values[2], values[3], values[4], values[5]
                )
                if !networkStatus || !attStatus || !apnsStatus {
                    return .launch
                }
                if !guideFlag {
                    return .guide
                }
                if !loginStatus || !configStatus {
                    return .launch
                }
                return .main
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.appState = state
            }
            .store(in: &cancellables)
    }

}
