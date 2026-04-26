//
//  MCCAppDelegate.swift
//

import UIKit
import Data
import Common
import Alamofire
import CoreTelephony
import Combine
import CombineExt
import MJRefresh

@main
public class MCCAppDelegate: UIResponder, UIApplicationDelegate {

    private var cancellables = Set<AnyCancellable>()
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        MCCViewControllerCore.swizzle()
        
        MCCLanguageTool.languages = [.en]
        MCCLanguageTool.defaultLanguage = .en
        MCCLanguageTool.shared.$currentLanguage
            .sink { MJRefreshConfig.default.languageCode = $0.code }
            .store(in: &cancellables)
        
        MCCNetworkConfig.shared.start(with: .current, environment: .current)
        MCCAppConfig.shared.$networkType
            .removeDuplicates()
            .sink { MCCNetworkConfig.shared.defaultHeader["X-Mnc-Network-Type"] = $0 }
            .store(in: &cancellables)
        MCCLanguageTool.shared.$currentLanguage
            .sink { MCCNetworkConfig.shared.defaultHeader["X-Mnc-Language"] = $0.codeToService }
            .store(in: &cancellables)

        MCCDatabaseManager.shared.initialization()
        MCCUserTableManager.shared.initialization()

        Publishers
            .CombineLatest(
                MCCAppConfig.shared.$networkStatus,
                MCCAppConfig.shared.$apnsStatus
            )
            .filter { $0 && $1 }
            .first()
            .sink { [weak self] _, _ in self?.loadData() }
            .store(in: &cancellables)

        Publishers
            .CombineLatest(
                MCCAppConfig.shared.$loginStatus,
                MCCAppConfig.shared.$deviceToken
            )
            .filter { $0 && !$1.isEmpty }
            .sink { [weak self] _, _ in self?.pushRegister() }
            .store(in: &cancellables)
        
        self.observeNetworkReachability()
//        self.attAuth()
        
        return true
    }

    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

extension MCCAppDelegate {

    private func observeNetworkReachability() {
        NetworkReachabilityManager.default?.startListening { status in
            switch status {
            case .notReachable:
                MCCAppConfig.shared.networkType = "--"
                MCCAppConfig.shared.networkStatus = false
            case .reachable(.ethernetOrWiFi):
                MCCAppConfig.shared.networkType = "WIFI"
                MCCAppConfig.shared.networkStatus = true
            case .reachable(.cellular):
                MCCAppConfig.shared.networkType = {
                    let currentStatus = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.values.first
                    switch currentStatus {
                    case "CTRadioAccessTechnologyCDMA1x":
                        return "2G"
                    case "CTRadioAccessTechnologyCDMAEVDORev0",
                         "CTRadioAccessTechnologyCDMAEVDORevA",
                         "CTRadioAccessTechnologyCDMAEVDORevB",
                         "CTRadioAccessTechnologyeHRPD":
                        return "3G"
                    case "CTRadioAccessTechnologyLTE":
                        return "4G"
                    case "CTRadioAccessTechnologyNRNSA",
                         "CTRadioAccessTechnologyNR":
                        return "5G"
                    default:
                        return "--"
                    }
                }()
                MCCAppConfig.shared.networkStatus = true
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }
    
//    public func attAuth() {
//        let status = ATTrackingManager.trackingAuthorizationStatus
//        switch status {
//        case .notDetermined:
//            print("att status is notDetermined")
//            MCCAppConfig.shared.attGranted = false
//            MCCAppConfig.shared.attStatus = false
//        case .denied, .restricted:
//            print("att status is denied/restricted")
//            MCCAppConfig.shared.attGranted = false
//            MCCAppConfig.shared.attStatus = true
//        case .authorized:
//            print("att status is authorized")
//            MCCAppConfig.shared.attGranted = true
//            MCCAppConfig.shared.attStatus = true
//        @unknown default:
//            print("att status is unknown")
//            MCCAppConfig.shared.attGranted = false
//            MCCAppConfig.shared.attStatus = true
//        }
//    }
//
//    public func attRequest() {
//        ATTrackingManager.requestTrackingAuthorization { status in
//            switch status {
//            case .notDetermined:
//                print("att status is notDetermined")
//                MCCAppConfig.shared.attGranted = false
//                MCCAppConfig.shared.attStatus = false
//            case .denied, .restricted:
//                print("att status is denied/restricted")
//                MCCAppConfig.shared.attGranted = false
//                MCCAppConfig.shared.attStatus = true
//            case .authorized:
//                print("att status is authorized")
//                MCCAppConfig.shared.attGranted = true
//                MCCAppConfig.shared.attStatus = true
//            @unknown default:
//                print("att status is unknown")
//                MCCAppConfig.shared.attGranted = false
//                MCCAppConfig.shared.attStatus = true
//            }
//        }
//    }
//
//    public func apnsAuthAndRequest() {
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            switch settings.authorizationStatus {
//            case .notDetermined:
//                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//                    print("apns status is \(granted)")
//                    MCCAppConfig.shared.apnsGranted = granted
//                    MCCAppConfig.shared.apnsStatus = true
//                }
//            case .authorized:
//                print("apns status is \(true)")
//                MCCAppConfig.shared.apnsGranted = true
//                MCCAppConfig.shared.apnsStatus = true
//            default:
//                print("apns status is \(false)")
//                MCCAppConfig.shared.apnsGranted = false
//                MCCAppConfig.shared.apnsStatus = true
//            }
//        }
//    }

    private func loadData() {
        self.login(next: self.config)
    }

    private func login(next: (() -> Void)?) {
        if MCCAppConfig.shared.loginStatus {
            next?()
            return
        }
        MCCUmAPIManager.shared.identityEstablish()
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.showAlert()
                }
            } receiveValue: { response in
                MCCAccountService.shared.updateCurrentUser(response)
                MCCAppConfig.shared.loginStatus = true
                next?()
            }
            .store(in: &cancellables)
    }

    private func config() {
        guard !MCCAppConfig.shared.configStatus else { return }
        Publishers
            .Zip(
                MCCCfAPIManager.shared.launcher(),
                MCCSubscriptionAPIManager.shared.fetchSubscriptionCatalog()
            )
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.showAlert()
                    return
                }
            } receiveValue: { _, _ in
                MCCAppConfig.shared.configStatus = true
            }
            .store(in: &cancellables)
    }

    private func pushRegister() {
        var requestModel: MCSPushRegisterRequest = .init()
        requestModel.token = MCCAppConfig.shared.deviceToken
        MCCPushAPIManager.shared.register(with: requestModel)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func showAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .dark
        alert.setValue({
            let att: NSMutableAttributedString = .init()
            att.append(.init(string: "程序初始化失败", attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.white
            ]))
            att.append(.init(string: "\n \n", attributes: [
                .font: UIFont.systemFont(ofSize: 1)
            ]))
            att.append(.init(string: "请检查网络后重试", attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]))
            att.addAttributes([
                .paragraphStyle: {
                    let style: NSMutableParagraphStyle = .init()
                    style.lineSpacing = 4
                    style.alignment = .center
                    return style
                }()
            ], range: .init(location: 0, length: att.length))
            return att
        }(), forKey: "attributedMessage")
        alert.addAction({
            let action = UIAlertAction(title: "重新加载", style: .default) { [weak self] _ in
                self?.loadData()
            }
            action.setValue(UIColor.white, forKey: "_titleTextColor")
            return action
        }())
        UIViewController.topViewController()?.present(alert, animated: true, completion: nil)
    }
}

public class MCCSceneDelegate: UIResponder, UIWindowSceneDelegate {

    private var cancellables = Set<AnyCancellable>()

    public var window: UIWindow?

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        self.window = {
            let window = UIWindow(windowScene: windowScene)
            window.backgroundColor = UIColor(hex: "0F0F12")
            window.tintColor = .systemBlue
            window.makeKeyAndVisible()
            return window
        }()
        MCCAppStateStore.shared.$appState
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .launch:
                    self.window?.rootViewController = MCCLaunchController.init()
                case .guide:
                    self.window?.rootViewController = MCCGuideController.init()
                case .main:
                    self.window?.rootViewController = MCCNavigationController(rootViewController: MCCTabBarController())
                }
            }
            .store(in: &cancellables)
    }
    
//    public func sceneDidBecomeActive(_ scene: UIScene) {
//        DispatchQueue.main.async {
//            guard MCCAppConfig.shared.networkStatus else {return}
//            if !MCCAppConfig.shared.attStatus {
//                self.attRequest()
//                return
//            }
//            self.apnsAuthAndRequest()
//        }
//    }
    
}

extension MCCViewControllerCore {

    public static func swizzle() {
        func exchange(_ original: Selector, _ swizzled: Selector) {
            guard
                let m1 = class_getInstanceMethod(MCCViewControllerCore.self, original),
                let m2 = class_getInstanceMethod(MCCViewControllerCore.self, swizzled)
            else { return }
            method_exchangeImplementations(m1, m2)
        }
        exchange(#selector(getter: preferredStatusBarStyle), #selector(_preferredStatusBarStyle))
        exchange(#selector(mcvc_configureNav), #selector(_configureNav))
    }

    @objc dynamic
    public func _preferredStatusBarStyle() -> UIStatusBarStyle {
        guard let style = self.navigationController?.navigationBar.mc_barStyle else {
            return .lightContent
        }
        switch style {
        case .transparentDark: return .darkContent
        case .transparentLight: return .lightContent
        }
    }

    @objc dynamic
    open func _configureNav() {
        self.navigationController?.navigationBar.mc_shadowHidden = true
        self.navigationController?.navigationBar.mc_barStyle = .transparentLight
        self.navigationItem.leftBarButtonItem = self.mcvc_needLeftBarButtonItem() ? .init(image: .init(named: "ic_nav_back")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(mcvc_leftBarButtonItemAction)) : .init(customView: UIView())

        _configureNav()
    }
    
}
