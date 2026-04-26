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
        get {
            if let nav = self.selectedViewController as? UINavigationController {
                return nav.topViewController?.fd_prefersNavigationBarHidden ?? false
            }
            return self.selectedViewController?.fd_prefersNavigationBarHidden ?? false
        }
        set {}
    }
    
    public override var fd_interactivePopDisabled: Bool {
        get {
            if let nav = self.selectedViewController as? UINavigationController {
                return nav.topViewController?.fd_interactivePopDisabled ?? false
            }
            return self.selectedViewController?.fd_interactivePopDisabled ?? false
        }
        set {}
    }
    
    // MARK: - Properties
    
    public var cancellables = Set<AnyCancellable>()
        
    public lazy var firstVC: MCCShotsController = {
        let vc = MCCShotsController()
        vc.tabBarItem.image = UIImage(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        vc.tabBarItem.title = "Shorts"
        return vc
    }()
    
    public lazy var secondVC: MCCToolsController = {
        let vc = MCCToolsController()
        vc.tabBarItem.image = UIImage(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        vc.tabBarItem.title = "Studio"
        return vc
    }()
    
    public lazy var thirdVC: MCCProjectsController = {
        let vc = MCCProjectsController()
        vc.tabBarItem.image = UIImage(named: "ic_tab_home")?.withRenderingMode(.alwaysTemplate)
        vc.tabBarItem.title = "Projects"
        return vc
    }()
    
    // MARK: - Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        let firstNav = MCCNavigationController(rootViewController: firstVC)
        firstNav.tabBarItem = firstVC.tabBarItem
        let secondNav = MCCNavigationController(rootViewController: secondVC)
        secondNav.tabBarItem = secondVC.tabBarItem
        let thirdNav = MCCNavigationController(rootViewController: thirdVC)
        thirdNav.tabBarItem = thirdVC.tabBarItem
        self.viewControllers = [firstNav, secondNav, thirdNav]
        
        self.tabBar.mc_barStyle = .glassDark
        
        NotificationCenter.default.publisher(for: .languageUpdated)
            .prepend(Notification(name: .languageUpdated))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.firstVC.tabBarItem.title = "Shorts"
                self.secondVC.tabBarItem.title = "Studio"
                self.thirdVC.tabBarItem.title = "Projects"
            }
            .store(in: &cancellables)
    }
    
}

extension MCCTabBarController: UITabBarControllerDelegate {
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        (viewController as? UINavigationController)?.setNavigationBarHidden(
            self.fd_prefersNavigationBarHidden,
            animated: false
        )
    }
    
}
