import UIKit
import WebKit
import SafariServices

class RecipeController: UIViewController, WKNavigationDelegate {
    
    var recipe:RecipeItem!
    var stayAwakeObserver:NSObjectProtocol?
    
    @IBOutlet var browser: WKWebView!
    @IBOutlet var titleBar: UINavigationBar!
    @IBOutlet var btnLock: UIBarButtonItem!
    @IBOutlet var btnActions: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.browser.navigationDelegate = self;
        loadRecipe()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
        appMovedToForeground(nil)
        stayAwakeObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: appMovedToForeground)
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil, using: self.appMovedToBackground)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationCenter.default.removeObserver(stayAwakeObserver as Any)
        
        if isEdited() {
            recipe.temp = browser.url?.absoluteString
            RecipeStore.shared.saveItemsToCache()
        }
    }
    
    //notifications
    func appMovedToForeground(_ notification: Notification?) {
        UIApplication.shared.isIdleTimerDisabled = false
        if isBaking() {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    func appMovedToBackground(_ notification: Notification?) {
        recipe.temp = browser.url?.absoluteString
    }
    
    
    //IBAction
    @IBAction func handleLock(sender: UIBarButtonItem){
        if isLocked() {
            if unlock() {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                RecipeStore.shared.saveItemsToCache()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        } else {
            if lock() {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                RecipeStore.shared.saveItemsToCache()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
    
    @IBAction func handleLongPress(recognizer:UILongPressGestureRecognizer) {
        NotificationCenter.default.post(name: Notification.Name.SwitchToBackoffice, object: self)
    }
       
    @IBAction func handleShare()
    {
        var extraActivities:[ShareRecipe] = []

//        let adminSafariItem = ShareRecipeShare(title: "Backoffice", image: UIImage(named: "admin")) { sharedItems in
//            NotificationCenter.default.post(name: Notification.Name.ShowBackoffice, object: self)
//        }
//        extraActivities.append(adminSafariItem)
//        
//        let webSafariItem = ShareRecipeShare(title: "Marketing", image: UIImage(named: "marketing")) { sharedItems in
//            guard let url = URL(string:  "https://sourdough.ovidiu.me/") else { return }
//            let safariVC = SFSafariViewController(url: url)
//            self.present(safariVC, animated: true, completion: nil)
//        }
//        extraActivities.append(webSafariItem)
//
//        let qrItem = ShareRecipeShare(title: "QR Images", image: UIImage(named: "qr_share")) { sharedItems in
//            NotificationCenter.default.post(name: Notification.Name.QRImages, object: self)
//        }
//        extraActivities.append(qrItem)
//

        let safariItem = ShareRecipeAction(title: "Open recipe in browser", image: UIImage(named: "safari")) { sharedItems in
            if let url = self.browser.url {
                //UIApplication.shared.open( URL(string: GithubStorage.externalLink(url.absoluteString ))!)
                let safariVC = SFSafariViewController(url: URL(string: GithubStorage.externalLink(url.absoluteString ))!)
                self.present(safariVC, animated: true, completion: nil)

            }
        }
        extraActivities.append(safariItem)
        
        
        let copyItem = ShareRecipeAction(title: "Copy recipe link", image: UIImage(named: "copy")) { sharedItems in
            UIPasteboard.general.string = GithubStorage.externalLink( self.browser.url!.absoluteString )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        extraActivities.append(copyItem)

        let exportItem = ShareRecipeAction(title: "Copy recipe as text", image: UIImage(named: "export")) { sharedItems in
            self.browser.evaluateJavaScript("(function() { return exportAsText(); })();", completionHandler: { result, error in
                if (error == nil) {
                    UIPasteboard.general.string = result as? String
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            })
        }
        
        extraActivities.append(exportItem)

        
        if !self.recipe.locked {
            if let clip = UIPasteboard.general.string {
                if clip.starts(with: externalDomain) {
                    let pasteItem = ShareRecipeAction(title: "Paste", image: UIImage(named: "paste")) { sharedItems in
                        if let url = URL(string: GithubStorage.localLink (clip) ) {
                            let link = url
                            let request = URLRequest(url: link)
                            self.recipe.temp =  GithubStorage.paramsOnly(clip)
                            
                            self.browser.load(request)
                            
                            self.tabBarItem.image = UIImage(named: "tab_filled")
                            self.titleBar.topItem!.title = "pasted"
                            self.titleBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.pasted]
                        }
                    }
                    extraActivities.append(pasteItem)
                }
            }
        }
        
        let sharedObjects = [AirDropOnlyActivityItemSource(item: GithubStorage.externalLink(self.browser.url!.absoluteString) as Any)]
        
        let activityVc = UIActivityViewController(activityItems: sharedObjects, applicationActivities: extraActivities)
        
        present(activityVc, animated: true)
        
    }
    
    
    func loadRecipe(){
        var link: URL {
            if let tmp = recipe.temp {
                return URL(string: GithubStorage.localLink (tmp) )!
            } else {
                return URL(string: GithubStorage.localLink (recipe.link) )!
            }
        }
        browser.loadFileURL(link, allowingReadAccessTo: siteFolder)
        updateUI()
    }
    
    //WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.isLoading {
            return
        }
        updateUILock()
    }
    
    func isNamed()->Bool{
        return recipe.name != RecipeItem.defaultName
    }
    
    func isEdited()->Bool {
        if let _ = browser {
            return GithubStorage.paramsOnly(browser.url!.absoluteString) != recipe.link
        }
        return false
    }
    
    func reset() {
        recipe.reset()
        let link = URL(string: recipe.link)!
        let request = URLRequest(url: link)
        browser.load(request)
    }
    
    func isLocked() -> Bool {
        return recipe.locked
    }

    func lock() -> Bool {
        if isNamed() {
            recipe.locked = true
            updateUI()
            return true
        } else {
            return false
        }
    }
    
    func unlock() -> Bool {
        if isBaking() {
            return false
        }
        recipe.locked = false
        updateUI()
        return true
    }
    
    func isBaking() -> Bool {
        return recipe.baking
    }
    
    func isSomethingBaking()->Bool {
        RecipeStore.shared.items.contains(where: { $0.baking })
    }
    
    func canBake() -> Bool {
        if isLocked() {
            return !isSomethingBaking()
        } else {
            return false
        }
    }
    
    func markForBake() {
        recipe.baking = true
        UIApplication.shared.isIdleTimerDisabled = false
        UIApplication.shared.isIdleTimerDisabled = true
        updateUI()
    }
    
    func unMarkForBaking() {
        recipe.baking = false
        UIApplication.shared.isIdleTimerDisabled = false
        updateUI()
    }
    
    func udateTitle(){
        titleBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.sourdough]
        if isLocked() {
            if isBaking() {
                self.tabBarItem.title = recipe.shortName
                self.titleBar.topItem!.title = "** \(recipe.shortName) **"
            } else {
                self.tabBarItem.title = recipe.shortName
                self.titleBar.topItem!.title = recipe.shortName
            }
        } else {
            if isNamed() {
                self.tabBarItem.title = recipe.shortName
                if (self.titleBar.topItem!.title != "pasted" ) {
                    self.titleBar.topItem!.title = recipe.shortName
                } else {
                    titleBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.pasted]
                }
            } else {
                self.tabBarItem.title = ""
                titleBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.gray]
                if (self.titleBar.topItem!.title != "pasted" ) {
                    self.titleBar.topItem!.title = "no name"
                } else {
                    titleBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.pasted]
                }
                
            }
        }
    }
    
    func updateTabIcon(){
        if isBaking() {
            self.tabBarItem.image = UIImage(named: "oven")
            self.tabBarItem.selectedImage = UIImage(named: "oven")
        } else {
            if (recipe.name != RecipeItem.defaultName) {
                self.tabBarItem.image = UIImage(named: "tab_filled")
                self.tabBarItem.selectedImage = UIImage(named: "tab_filled")
            } else {
                self.tabBarItem.image = UIImage(named: "tab")
                self.tabBarItem.selectedImage = UIImage(named: "tab")
            }
        }
    }
    
    func setupLockIcon(){
        if isLocked() {
            btnLock.image = UIImage(named: "locked")
        } else {
            btnLock.image = UIImage(named: "unlocked")
        }
    }
    
    func setupLockJS(){
        if isLocked() {
            self.browser.evaluateJavaScript("$('#wf_slider').slider({ disabled: true });$('input').prop( 'disabled', true );$('.increment-button').addClass('readonly'); $('#qty').addClass('orange');$('#wf_split').addClass('orange');$('#add-button-div').hide();")
        } else {
            self.browser.evaluateJavaScript("$('#wf_slider').slider({ disabled: false });$('input').prop( 'disabled', false );$('.increment-button').removeClass('readonly');  $('#qty').removeClass('orange'); $('#wf_split').removeClass('orange');$('#add-button-div').show();")
        }
    }
    
    func setupBakeJS(){
        if isBaking() {
            self.browser.evaluateJavaScript("$('.increment-button-qty').addClass('readonly');")
        } else {
            self.browser.evaluateJavaScript("$('.increment-button-qty').removeClass('readonly');")
        }
    }
    
    
    func updateUI(){
        udateTitle()
        updateTabIcon()
        updateUILock()
    }
    
    func updateUILock(){
        setupLockIcon()
        setupLockJS()
        setupBakeJS()
    }
    
}
