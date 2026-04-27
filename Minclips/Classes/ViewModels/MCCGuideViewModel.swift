import Foundation
import Combine

public final class MCCGuideViewModel: MCCBaseViewModel {

    @Published var models: [MCSGuide] = []

    public func loadData() {
        models = [
            MCSGuide(
                id: "guide-1",
                media: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=960&q=80",
                title: "Direct Your Story",
                detail: "Turn idea into cinematic episodes. No camera needed.",
                handleBtnTitle: "Continue",
                pageStyle: .story
            ),
            MCSGuide(
                id: "guide-2",
                media: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=960&q=80",
                title: "Infinite Storylines",
                detail: "Chain clips together, extend the narrative, and keep your characters perfectly consistent.",
                handleBtnTitle: "Continue",
                pageStyle: .story
            ),
            MCSGuide(
                id: "guide-3",
                media: "",
                title: "Cast Your Lead",
                detail: "Upload a photo to create your story's lead.",
                handleBtnTitle: "Start Creating",
                pageStyle: .castLead
            ),
        ]
    }

}
