import Foundation
import WebKit

class BackofficeController: UIViewController  {
    
    var scannerController: ScannerViewController!;
    var qrImagesController: QRCodesViewController!;
    
    @IBOutlet var browser: WKWebView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var titleBar: UINavigationItem!

    private let logo = UIImageView(image: UIImage(named: "icon"))
    private var savedView:UIView!
    
    @IBAction func done(){
        self.dismiss(animated: true)
    }

    @IBAction func refresh(){
        self.browser.reload();
    }
    
    @IBAction func clearCache(){
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        self.browser.reload();
    }
    
    @IBAction func startQR(){
        NotificationCenter.default.post(name: Notification.Name.QRScanner, object: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil, using: self.appMovedToBackground)

        scannerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScannerViewController") as? ScannerViewController

        qrImagesController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRImagesViewController") as? QRCodesViewController

        NotificationCenter.default.addObserver(forName: Notification.Name.QRScanner, object: nil, queue: nil, using:self.showQRScanner)

        NotificationCenter.default.addObserver(forName: Notification.Name.QRImages, object: nil, queue: nil, using:self.showQRImages)


        savedView = self.titleBar.titleView
        self.titleBar.titleView = logo
        
        browser.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        browser.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        browser.load(URLRequest(url: URL(string:"https://sdbot.ovidiu.me/admin/overview/")!))
    }

    func appMovedToBackground(_ notification: Notification?) {
        scannerController.dismiss(animated: false)
        qrImagesController.dismiss(animated: false)
    }
    
    func showQRScanner(_ notification: Notification?) {
        if (self.presentedViewController != self.scannerController) {
            if let p = self.presentedViewController {
                p.present(self.scannerController, animated: true)
            } else {
                self.present(self.scannerController, animated: true)
            }
        }
    }
    
    func showQRImages(_ notification: Notification?) {
        if (self.presentedViewController != self.qrImagesController) {
            if let p = self.presentedViewController {
                p.present(self.qrImagesController, animated: true)
            } else {
                self.present(self.qrImagesController, animated: true)
            }
        }
        
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            if browser.title == "" {
                self.titleBar.titleView = logo
            } else {
                titleBar.title = browser.title
                self.titleBar.titleView = savedView
            }
        } else if keyPath == "estimatedProgress" {
            self.progressView.progress = Float(self.browser.estimatedProgress)
                if (self.progressView.progress == 1) {
            self.progressView.progress = 0
            }
        }
    }
        
}
