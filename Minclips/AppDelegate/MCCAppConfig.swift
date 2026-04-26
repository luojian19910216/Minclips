import Common
import Combine

public class MCCAppConfig: NSObject {
    
    public static let shared = MCCAppConfig()

    @Published public var networkStatus: Bool = false

    @Published public var networkType: String = ""

    @Published public var apnsStatus: Bool = true

    public var apnsGranted: Bool = false

    @Published public var deviceToken: String = ""

    @Published public var attStatus: Bool = true

    public var attGranted: Bool = false

    @Published public var loginStatus: Bool = false

    @Published public var configStatus: Bool = false

    @MCCUserDefaultsPublished(key: "guide", default: false)
    public var guideFlag: Bool

}
