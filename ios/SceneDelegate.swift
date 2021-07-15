import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var mainController: MainViewController!;
    var backofficeController: BackofficeController!;
    
    //cold start
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        //setup
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene
        window?.makeKeyAndVisible()
        
        //initialize quick actions
        var shortcutItems = UIApplication.shared.shortcutItems ?? []
        //shortcutItems = []
        if shortcutItems.isEmpty {
            shortcutItems += [
                UIApplicationShortcutItem(type: "sourdough.backoffice", localizedTitle: "Backoffice", localizedSubtitle: "", icon: UIApplicationShortcutIcon(templateImageName: "telegram")),
                UIApplicationShortcutItem(type: "sourdough.qr", localizedTitle: "QR Scanner", localizedSubtitle: "", icon: UIApplicationShortcutIcon(templateImageName: "camera")),
                UIApplicationShortcutItem(type: "sourdough.qr_images", localizedTitle: "QR Codes", localizedSubtitle: "", icon: UIApplicationShortcutIcon(templateImageName: "qr"))
            ]
            UIApplication.shared.shortcutItems = shortcutItems
        }
        
        //initialize controllers
        mainController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as? MainViewController
        
        backofficeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BackofficeController") as? BackofficeController
        backofficeController.loadViewIfNeeded()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.ShowBackoffice, object: nil, queue: nil, using:self.showBackoffice)
        
        
        NotificationCenter.default.addObserver(forName:  Notification.Name.SwitchToRecipes , object: nil, queue: .main) { [weak self] notification in
            self?.window?.rootViewController = self?.mainController
            self?.shortcut = "sourdough.recipes"
            self?.setupQuickAction()
        }
        
        NotificationCenter.default.addObserver(forName:  Notification.Name.SwitchToBackoffice , object: nil, queue: .main) { [weak self] notification in
            self?.window?.rootViewController = self?.backofficeController
            self?.shortcut = "sourdough.backoffice"
            self?.setupQuickAction()
        }
                
        if let shortcutItem = connectionOptions.shortcutItem {
            shortcut = shortcutItem.type
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge]) { (granted, error) in
                   // Enable or disable features based on authorization.
               }
        
    }
    
    func setupQuickAction(){
        var shortcutItems = UIApplication.shared.shortcutItems ?? []
        if let mutableShortcutItem = shortcutItems.first?.mutableCopy() as? UIMutableApplicationShortcutItem {
            if shortcut == "sourdough.backoffice" {
                mutableShortcutItem.type = "sourdough.recipes"
                mutableShortcutItem.localizedTitle = "Recipes"
                mutableShortcutItem.icon = UIApplicationShortcutIcon(templateImageName: "oven")
                UIApplication.shared.applicationIconBadgeNumber = 1
            } else {
                mutableShortcutItem.type = "sourdough.backoffice"
                mutableShortcutItem.localizedTitle = "Backoffice"
                mutableShortcutItem.icon = UIApplicationShortcutIcon(templateImageName: "telegram")
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        shortcutItems[0] = mutableShortcutItem
        }
        UIApplication.shared.shortcutItems = shortcutItems
    }
    
    //from background
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        shortcut = shortcutItem.type
        
        completionHandler(true)
    }
    
    
    func showBackoffice(_ notification: Notification?) {
        if let url = notification?.userInfo?["goto"] as? String {
            print("will load \(url)...")
            self.backofficeController.browser.load(URLRequest(url: URL(string: url)!))
        }
        if (self.window?.rootViewController != self.backofficeController) {
            self.window?.rootViewController = self.backofficeController
        }
    }
    
    var shortcut: String {
        get{
            if let s = UserDefaults.standard.string(forKey: "sourdough.shortcut") {
                return s
            } else {
                return "sourdough.recipes"
            }
        }
        set(val) {
            UserDefaults.standard.set(val, forKey: "sourdough.shortcut")
        }

    }

    
    func sceneWillEnterForeground(_ scene: UIScene) {
            if (self.shortcut == "sourdough.recipes") {
                self.window?.rootViewController = self.mainController
            } else {
                self.window?.rootViewController = self.backofficeController

                if (self.shortcut == "sourdough.qr") {
                    NotificationCenter.default.post(name: Notification.Name.QRScanner, object: self)
                }
                if (self.shortcut == "sourdough.qr_images") {
                    NotificationCenter.default.post(name: Notification.Name.QRImages, object: self)
                }
                self.shortcut = "sourdough.backoffice"
            }
            setupQuickAction()
    }
    
}

