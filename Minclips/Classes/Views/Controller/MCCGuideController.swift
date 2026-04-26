import UIKit
import Combine

public class MCCGuideController: MCCViewController<MCCGuideView, MCCGuideViewModel> {

    public override func mcvc_bind() {
        self.contentView.bindInput(
            MCCGuideViewInput(
                models: self.viewModel.$models
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            )
        )

        self.contentView.output
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event {
                case .primaryTapped(_, _, let isLastPage):
                    if isLastPage {
                        MCCAppConfig.shared.guideFlag = true
                    }

                case .pageIndexChanged:
                    break
                }
            }
            .store(in: &cancellables)
    }

    public override func mcvc_loadData() {
        self.viewModel.loadData()
    }

}
