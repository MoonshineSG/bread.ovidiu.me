import UIKit

class MainViewController: UITabBarController, UITabBarControllerDelegate {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        GithubStorage.download(completionHandler: {
            self.selectedIndex = self.loadRecipes()
            
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil, using: self.appMovedToBackground)
            
            NotificationCenter.default.addObserver(forName: Notification.Name.ReloadAllTabs, object: nil, queue: nil, using:self.reloadAllTabs)
        })

    }
    
    //notifications
    
    //notifications
    func reloadAllTabs(_ notification: Notification?) {
        let idx = self.loadRecipes()
        if let tab = notification?.userInfo?["tab"] as? Int {
            selectedIndex = tab
        } else {
            selectedIndex = idx
        }
    }    
    
    func appMovedToBackground(_ notification: Notification?) {
        UIApplication.shared.isIdleTimerDisabled = false
        RecipeStore.shared.saveItemsToCache()
    }
    
    //IBActions
    @IBAction func handleLongTap(recognizer:UILongPressGestureRecognizer) {
        if recognizer.state == .began {

            let buttonWidth = tabBar.frame.size.width/CGFloat(tabBar.items!.count)
            let touched = recognizer.location(in: tabBar)
            let index = Int(touched.x/buttonWidth)
            
            if index != self.selectedIndex {
                return
            }
            
            guard let tapController = self.viewControllers![index] as? RecipeController else {
                return
            }
            guard let controller = self.selectedViewController as? RecipeController else  {
                return
            }
            if ( tapController.isLocked() ) {
                
                if ( tapController.isBaking() ) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    tapController.unMarkForBaking()
                } else {
                    if tapController.canBake() {
                        tapController.markForBake()
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            } else {

                let saveController = UIAlertController(title: "Save as", message: "[saves active recipe in selected tab]", preferredStyle: .alert)
                
                saveController.addTextField { (textField : UITextField!) -> Void in
                    textField.clearButtonMode = .always
                    if ( controller.isNamed() ) {
                        textField.text = controller.recipe.name
                        textField.isSelected = true
                    }
                }
                
                let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
                    let nameField = saveController.textFields![0] as UITextField
                    
                    if (nameField.text?.trimmingCharacters(in: .whitespaces) == "" ){
                        tapController.reset()
                    } else {
                        _ = tapController.lock()
                        tapController.recipe.name = (nameField.text?.trimmingCharacters(in: .whitespaces) as String?)!
                        tapController.recipe.link = (controller.browser.url?.absoluteString as String?)!
                        tapController.recipe.temp = nil
                    }
                    
                    DispatchQueue.main.async {
                        let _ = self.loadRecipes()
                    }
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action : UIAlertAction!) -> Void in })
                
                saveController.addAction(cancelAction)
                saveController.addAction(saveAction)
                
                self.present(saveController, animated: true, completion: nil)
            }
        }
    }
    
    
    @IBAction func handleDoubleTap(recognizer:UITapGestureRecognizer) {

        let buttonWidth = tabBar.frame.size.width/CGFloat(tabBar.items!.count)
        let touched = recognizer.location(in: tabBar)
        let index = Int(touched.x/buttonWidth)
        
        if index != self.selectedIndex {
            return
        }

        guard let tapController = self.viewControllers![index] as? RecipeController else {
            return
        }
        
        guard let controller = self.selectedViewController as? RecipeController else  {
            return
        }
        if controller !=  tapController {
            return
        }
        
        if controller.isLocked() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        clearCache()
        if controller.isEdited() {
            let reloadController = UIAlertController(title: "Reload", message: "[you will loose changes made to this recipe]", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .destructive, handler: { alert -> Void in
                controller.recipe.temp = nil
                controller.titleBar.topItem!.title = ""
                RecipeStore.shared.saveItemsToCache()
                controller.loadRecipe()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action : UIAlertAction!) -> Void in })
            
            reloadController.addAction(cancelAction)
            reloadController.addAction(okAction)
            
            self.present(reloadController, animated: true, completion: nil)
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            controller.loadRecipe()
        }
    }
    
    func loadRecipes()-> Int{
        var array:[UIViewController] = []
        var baking = 0
                
        for (idx, recipe) in RecipeStore.shared.recipes_to_show().enumerated(){
            let newRecipeController: RecipeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewRecipe") as! RecipeController
            newRecipeController.recipe = recipe
            array.append(newRecipeController)
            if (recipe.baking){
                baking = idx
            }
            DispatchQueue.main.async {
                newRecipeController.view.setNeedsLayout()
            }
        }
        let more = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MoreRecipe")
        array.append(more)
        more.view.setNeedsLayout()
        for c in self.children {
            c.dismiss(animated: false, completion: nil)
        }
        self.setViewControllers(array, animated: false)
        return baking
    }
    
}



