//
//  MCCTabBarController.swift
//

import UIKit
import Common
import Combine
import FDFullscreenPopGesture

public class MCCTabBarController: UITabBarController {
        
    // MARK: - Autorotate
    
    open override var shouldAutorotate: Bool {
        return self.selectedViewController?.shouldAutorotate ?? false
    }
    
    // MARK: - Orientation
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.selectedViewController?.supportedInterfaceOrientations ?? .portrait
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.selectedViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
    
    // MARK: - StatusBar
    
    open override var childForStatusBarHidden: UIViewController? {
        return self.selectedViewController
    }
    
    open override var childForStatusBarStyle: UIViewController? {
        return self.selectedViewController
    }
       
    // MARK: - NavigationBar
    
    public override var fd_prefersNavigationBarHidden: Bool {
        get { self.selectedViewController?.fd_prefersNavigationBarHidden ?? false }
        set {}
    }
    
    public override var fd_interactivePopDisabled: Bool {
        get { self.selectedViewController?.fd_interactivePopDisabled ?? false }
        set {}
    }
    
    // MARK: - Properties
    
    public var cancellables = Set<AnyCancellable>()
        
    public lazy var firstVC: MCCShopHomeController = {
        let vc: MCCShopHomeController = .init()
        vc.tabBarItem.image = UIImage.init(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        return vc
    }()
    
    public lazy var secondVC: MCCShopCategoryController = {
        let vc: MCCShopCategoryController = .init()
        vc.tabBarItem.image = UIImage.init(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        return vc
    }()
    
    public lazy var thirdVC: MCCShopCartController = {
        let vc: MCCShopCartController = .init()
        vc.tabBarItem.image = UIImage.init(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        return vc
    }()
    
    public lazy var fourVC: MCCUserHomeController = {
        let vc: MCCUserHomeController = .init()
        vc.tabBarItem.image = UIImage.init(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        return vc
    }()
    
    // MARK: - Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.viewControllers = [firstVC, secondVC, thirdVC, fourVC]
        
        self.tabBar.mc_barStyle = .glassDark
        
        NotificationCenter.default.publisher(for: .languageUpdated)
            .prepend(Notification(name: .languageUpdated))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.firstVC.tabBarItem.title = "标题"
                self.secondVC.tabBarItem.title = "标题"
                self.thirdVC.tabBarItem.title = "标题"
                self.fourVC.tabBarItem.title = "标题"
            }
            .store(in: &cancellables)
    }
    
}

extension MCCTabBarController: UITabBarControllerDelegate {
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.navigationController?.setNavigationBarHidden(self.fd_prefersNavigationBarHidden, animated: false)
    }
    
}
