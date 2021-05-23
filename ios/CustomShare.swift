import UIKit
import LinkPresentation

class AirDropOnlyActivityItemSource: NSObject, UIActivityItemSource {
    
    let item: Any
    
    private var metadata:LPLinkMetadata {
        let metadata = LPLinkMetadata()
        metadata.originalURL = URL(string: externalDomain)
        metadata.url = metadata.originalURL
        metadata.title = "Bread Calculator"
        metadata.iconProvider = NSItemProvider.init(contentsOf: siteFolder.appendingPathComponent("icon.png") )
        return metadata
    }
    
    init(item: Any) {
        self.item = item
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return NSURL(string: "")!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return item
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
}


class ShareRecipe: UIActivity {
    var _activityTitle: String
    var _activityImage: UIImage?
    var activityItems = [Any]()
    var action: ([Any]) -> Void
    
    init(title: String, image: UIImage?, performAction: @escaping ([Any]) -> Void) {
        _activityTitle = title
        _activityImage = image
        action = performAction
        super.init()
    }
    
    override var activityTitle: String? {
        return _activityTitle
    }
    
    override var activityImage: UIImage? {
        return _activityImage
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: "me.ovidiu.sourdough.activity")
    }
        
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }
}

class ShareRecipeShare: ShareRecipe {
    override class var activityCategory: UIActivity.Category {
        return .share
    }
}
    
class ShareRecipeAction: ShareRecipe {
        override class var activityCategory: UIActivity.Category {
            return .action
    }
}
