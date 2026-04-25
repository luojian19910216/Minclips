//
//  MCCGuideViewModel.swift
//

import Foundation
import Combine

public final class MCCGuideViewModel: MCCBaseViewModel {
    
    @Published var models: [MCSGuide] = []
    
    public func loadData() {
        self.models = [
            .init(media: "", title: "啊说大话山东科技阿是", detail: "啊说大话山东科技阿是", handleBtnTitle: "asdad"),
            .init(media: "", title: "啊说大话山东科技阿是", detail: "啊说大话山东科技阿是", handleBtnTitle: "asdad"),
            .init(media: "", title: "啊说大话山东科技阿是", detail: "啊说大话山东科技阿是", handleBtnTitle: "asdad"),
        ]
    }
}
