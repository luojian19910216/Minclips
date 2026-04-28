import UIKit
import Combine
import PhotosUI

public class MCCGuideController: MCCViewController<MCCGuideView, MCCEmptyViewModel> {

    private let guideModelsSubject = CurrentValueSubject<[MCSGuide], Never>([])

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let bg = UIColor.black
        view.backgroundColor = bg
        contentView.backgroundColor = bg
    }

    public override func mcvc_bind() {
        contentView.bindInput(
            MCCGuideViewInput(
                models: guideModelsSubject
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            )
        )

        contentView.output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .primaryTapped(_, _, let isLastPage):
                    if isLastPage {
                        MCCAppConfig.shared.guideFlag = true
                    }
                case .pickPhotoTapped:
                    mcvc_presentPhotoPicker()
                }
            }
            .store(in: &cancellables)
    }

    public override func mcvc_loadData() {
        guideModelsSubject.send(Self.mcvc_makeGuideModels())
    }

    private static func mcvc_makeGuideModels() -> [MCSGuide] {
        [
            .story(
                media: "ic_bg_guide_1",
                title: "Direct Your Story",
                detail: "Turn idea into cinematic episodes. No camera needed.",
                button: "Continue"
            ),
            .story(
                media: "ic_bg_guide_2",
                title: "Infinite Storylines",
                detail: "Chain clips together, extend the narrative, and keep your characters perfectly consistent.",
                button: "Continue"
            ),
            .cast(
                title: "Cast Your Lead",
                detail: "Upload a photo to create your story's lead.",
                button: "Start Creating"
            ),
        ]
    }

    private func mcvc_presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

}

extension MCCGuideController: PHPickerViewControllerDelegate {

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let r = results.first else { return }
        if let id = r.assetIdentifier {
            MCCRecentPickedPhotoStore.record(localIdentifier: id)
        }
        let prov = r.itemProvider
        guard prov.canLoadObject(ofClass: UIImage.self) else { return }
        _ = prov.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            let img = object as? UIImage
            DispatchQueue.main.async {
                if r.assetIdentifier == nil,
                   let img,
                   let data = img.jpegData(compressionQuality: 0.92) ?? img.pngData() {
                    _ = MCCRecentPickedPhotoStore.recordFallbackJPEGData(data)
                }
                self?.contentView.mcvw_setCastLeadPreview(image: img)
            }
        }
    }

}
