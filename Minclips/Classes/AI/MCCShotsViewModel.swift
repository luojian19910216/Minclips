//
//  MCCShotsViewModel.swift
//

import Foundation
import Combine
import Data
import Common

public final class MCCShotsViewModel: MCCBaseViewModel, ObservableObject {

    @Published public private(set) var tagsState = MCSLoadState<MCSList<MCSFeedLabelItem>>()
    @Published public private(set) var selectedTagIndex: Int = 0

    public var labelItems: [MCSFeedLabelItem] { tagsState.model?.items ?? [] }

    public func mcsv_loadTags() {
        selectedTagIndex = 0
        MCCFeedAPIManager.shared.customLabels()
            .asLoadState()
            .sink { [weak self] state in
                self?.tagsState = state
            }
            .store(in: &cancellables)
    }

    public func mcsv_selectTag(at index: Int) {
        guard index >= 0, index < labelItems.count else { return }
        selectedTagIndex = index
    }

    public var mcsv_currentRefId: String? {
        labelItems[safe: selectedTagIndex]?.templateRef
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
