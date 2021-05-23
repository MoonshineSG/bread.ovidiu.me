import SystemConfiguration
import WebKit

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
}

extension UIColor {
    //orange
    class var sourdough: UIColor { return UIColor(red: 0.89, green: 0.31, blue: 0.00, alpha: 1.00) }
    //green
    class var sourdough_green: UIColor { return UIColor(red: 0.29, green: 0.68, blue: 0.53, alpha: 1.00) }
    
    class var pasted: UIColor { return UIColor(red: 0, green: 0.5765, blue: 0.8863, alpha: 1.0)  }    
    class var transparentBlack: UIColor { return UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)  }
    
}

extension NSNotification.Name {
 //   public static let SaveToCache: NSNotification.Name = NSNotification.Name(rawValue: "SaveToCache")
    public static let QRScanner: NSNotification.Name = NSNotification.Name(rawValue: "QRScanner")
    public static let QRImages: NSNotification.Name = NSNotification.Name(rawValue: "QRImages")
    public static let ShowBackoffice: NSNotification.Name = NSNotification.Name(rawValue: "ShowBackoffice")
    public static let ReloadAllTabs: NSNotification.Name = NSNotification.Name(rawValue: "ReloadAllTabs")
    
}



func clearCache(){
    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
    WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
        records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
        }
    }
}

