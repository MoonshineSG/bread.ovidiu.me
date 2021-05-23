import Zip
import Alamofire

var externalDomain: String {
    if let s = UserDefaults.standard.string(forKey: "CURRENT_GITHUB_DOMAIN") {
        return s
    } else {
        return "https://bread.ovidiu.me"
    }
}

let siteFolder = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0].appendingPathComponent("site", isDirectory:true)

class GithubStorage {
      
    //if using private repostitory
    //private static let authHTTPHeader = HTTPHeader(name: "Authorization", value: "token XXXXX")
    
    private static let archiveDestination: DownloadRequest.Destination = { _, _ in
        return (archive, [.removePreviousFile, .createIntermediateDirectories])
    }
    
    private static let archive = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("archive.zip", isDirectory:false)
    
    class func paramsOnly(_ link: String)-> String {
        guard let idx = link.firstIndex(of: "?") else { return link }
        return String ( link.suffix( from:  link.index(after: idx)) )
    }

    class func externalLink(_ params: String)-> String{
        let clean = paramsOnly(params) //safety
        return "\(externalDomain)/?\(clean)"
    }
    
    class func localLink(_ params: String)-> String{
        let clean = paramsOnly(params) //safety
        return  "\(siteFolder.appendingPathComponent("index.html", isDirectory:false))?\(clean)"
    }
    
    private class func downloadAndUnzip(_ urlForLatestCode: String, latestSHA: String, completionHandler:  @escaping (() -> Swift.Void) ){
        print("updating to \(latestSHA) from \(urlForLatestCode)")
        // if using private repo, add::   headers: [authHTTPHeader],
        AF.download(urlForLatestCode, to: archiveDestination) .downloadProgress { progress in
        } .responseData { response in
            do {
                var fromName = siteFolder
                try Zip.unzipFile(archive, destination: FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0], overwrite: true, password: nil, fileOutputHandler: { url in
                    
                    if url.absoluteString.hasSuffix("CNAME") {
                        do {
                            let dom = try String(contentsOfFile: url.absoluteString, encoding: .utf8)
                            UserDefaults.standard.set("https://\(dom)", forKey: "CURRENT_GITHUB_DOMAIN")
                            fromName = url.deletingLastPathComponent()
                        }
                        catch let error  {
                            print("error \(error)")
                            completionHandler()
                            return
                        }
                    }
                })
                try FileManager.default.removeItem(at: archive)
                do {
                    try FileManager.default.removeItem(at: siteFolder)
                } catch   {}
                try FileManager.default.moveItem(atPath: fromName.path, toPath: siteFolder.path)
                UserDefaults.standard.set(latestSHA, forKey: "CURRENT_GITHUB_VERSION")
                completionHandler()
            } catch  let error  {
                print("error \(error)")
            }
        }
    }
    
    class func download(completionHandler:  @escaping (() -> Swift.Void)){
        if Reachability.isConnectedToNetwork(){
            // if using private repo, add::   headers: [authHTTPHeader],
            AF.download("https://api.github.com/repos/MoonshineSG/bread.ovidiu.me/commits", to: archiveDestination) .downloadProgress { progress in
            }.responseJSON { response in
                if let status = response.response?.statusCode {
                    if status == 200 {
                        let JSON = response.value as! [NSDictionary]
                        if let latestSHA = (JSON[0]["sha"] as? String) {
                            let currentSHA = UserDefaults.standard.string(forKey: "CURRENT_GITHUB_VERSION")
                            if latestSHA != currentSHA {
                                downloadAndUnzip("https://api.github.com/repos/MoonshineSG/bread.ovidiu.me/zipball", latestSHA: latestSHA, completionHandler: completionHandler)
                                clearCache()
                                return
                            }
                        }
                    }
                }
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }
}
