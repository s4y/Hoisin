import Cocoa

private enum AppDefault {
    case MonospacedFont
}

extension String {
    private init(_ appDefault: AppDefault) {
        switch appDefault {
        case .MonospacedFont: self = "MonospacedFont"
        }
    }
}

class AppDefaults {
    private let defaults: NSUserDefaults
    
    dynamic var monospacedFont: NSFont? {
        get {
            let f = self.defaults.dictionaryForKey(String(AppDefault.MonospacedFont))!
            return NSFont(
                name: f["Name"] as! String,
                size: CGFloat((f["Size"] as! NSNumber).doubleValue)
            )
        }
        set {
            if let newValue = newValue {
                self.defaults.setObject([
                    "Name": newValue.fontName,
                    "Size": newValue.pointSize
                ] as NSDictionary, forKey: String(AppDefault.MonospacedFont))
            } else {
                self.defaults.removeObjectForKey(String(AppDefault.MonospacedFont))
            }
        }
    }
    
    private init(defaults: NSUserDefaults) {
        self.defaults = defaults
    }
    
    static let shared = AppDefaults(defaults: NSUserDefaults.standardUserDefaults())
}