import UIKit
import SnapKit

public class MCCLaunchView: MCCBaseView {
    
    public lazy var imageView: UIImageView = {
        let v: UIImageView = .init()
        v.image = .init(named: "AppLaunch")
        return v
    }()
    
    public override func mcvw_setupUI() {
        self.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }
    }

}
