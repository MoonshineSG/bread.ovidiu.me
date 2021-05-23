import UIKit

final class RecipeItem: NSObject {
    static let defaultName: String = "@@@@@@"
    static let defaultParams: String = "flour=377&water=72&salt=1.8&levain=25&qty=1&split=100"
    
    var name: String = RecipeItem.defaultName
    var link: String = RecipeItem.defaultParams
    var locked: Bool = false
    var baking: Bool = false
    
    var temp:String?
    
    init(link: String, name: String) {
        self.name = name
        self.link = link
    }
    
    var shortName: String {
        if ( name.count > 16 ) {
            return "\( name.prefix(16) )..."
        } else {
            return name
        }
    }
    
    func lock(status: Bool){
        self.locked = status
    }
    
    func bake(status: Bool){
        self.baking = status
    }
    
    class func empty()->RecipeItem {
        return RecipeItem(link: defaultParams, name: defaultName)
    }
    
    func reset(){
        self.name = RecipeItem.defaultName
        self.link = RecipeItem.defaultParams
        self.locked = false
        self.baking = false
        self.temp = nil
    }
    
    override var description: String {
        return "\(name) : \(link)\(locked ? " [locked] " : "")\(baking ? " [baking] " : "")\n temp: ['\( temp  ?? "" )]' \n"
    }
    
}

extension RecipeItem: NSCoding {
    struct CodingKeys {
        static let Name = "name"
        static let Link = "link"
        static let Locked = "locked"
        static let Baking = "baking"
        static let Temp = "temp"
    }
    
    convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.Name) as? String ?? RecipeItem.defaultName
        let link = aDecoder.decodeObject(forKey: CodingKeys.Link) as? String ?? RecipeItem.defaultParams
        self.init(link: GithubStorage.paramsOnly(link), name: name)
        self.locked = aDecoder.decodeBool(forKey: CodingKeys.Locked)
        self.baking = aDecoder.decodeBool(forKey: CodingKeys.Baking)
        if let tmp = aDecoder.decodeObject(forKey: CodingKeys.Temp) as? String {
            self.temp = tmp
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: CodingKeys.Name)
        aCoder.encode(GithubStorage.paramsOnly(link), forKey: CodingKeys.Link)
        aCoder.encode(locked, forKey: CodingKeys.Locked)
        aCoder.encode(baking, forKey: CodingKeys.Baking)
        if ( temp != nil ) {
            aCoder.encode(temp, forKey: CodingKeys.Temp)
        }
        
    }
}

class RecipeStore: NSObject {
    let semaphore = DispatchSemaphore(value: 1)
    
    static let shared = RecipeStore()
    
    var items: [RecipeItem] = []
    
    private override init() {
        super.init()
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        loadItemsFromCache()
        semaphore.signal()
    }
    
    func recipes_to_show()->[RecipeItem]{
        return Array(items.prefix(4))
    }
    
    func saveItemsToCache() {
        do {
            //print("saveItemsToCache\n")
            let data = try NSKeyedArchiver.archivedData(withRootObject: items, requiringSecureCoding: false)
            print("Save to \(itemsCachePath)")
            try data.write(to: itemsCachePath)
        } catch {
            print("Couldn't write file.")
        }
    }
    
    func loadItemsFromCache() {
        print("loadItemsFromCache \(itemsCachePath)")
        if let nsData = NSData(contentsOf: itemsCachePath) {
            do {
                let data = Data(referencing:nsData)
                if let cachedItems = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [RecipeItem]  {
                    items = cachedItems
                    print("======= LOAD \(self.items.count) \n")
                }
            } catch {
                print("Couldn't read file.")
                return
            }
        }
    }
    
    var itemsCachePath: URL {
        
        let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents")
        
//        let localDocumentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        
//        do {
//            try FileManager.default.copyItem(at: localDocumentsURL.appendingPathComponent("recipes.db"), to: iCloudDocumentsURL.appendingPathComponent("recipes.db"))
//        }
//        catch { print("Failed to copy to iCloud...") }
        
        
        return iCloudDocumentsURL.appendingPathComponent("recipes.db")
    }
}
