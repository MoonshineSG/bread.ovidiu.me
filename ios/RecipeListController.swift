import UIKit


class RecipeListContainer: UIViewController
{
    
    override func viewDidAppear(_ animated: Bool) {
        cancelButton.tintColor = UIColor.sourdough
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let tableViewController = children.first as? RecipeListController else  {
           fatalError("Check storyboard for missing RecipeListController")
         }
        
        if tableViewController.isEditing {
            cancelTableView(sender: cancelButton)
        }
    }
        
    
    @IBOutlet var cancelButton:UIBarButtonItem!
    @IBOutlet var editButton:UIBarButtonItem!
    
    
    @IBAction func cancelTableView (sender:UIBarButtonItem)
    {
        guard let tableViewController = children.first as? RecipeListController else  {
           fatalError("Check storyboard for missing RecipeListController")
         }
        
        if tableViewController.isEditing {
            tableViewController.setEditing(false, animated: true);
            editButton.title = "Edit";
            cancelButton.image = UIImage(named: "plus")
            
            RecipeStore.shared.loadItemsFromCache()
            tableViewController.tableView.reloadData()
        } else {
            tableViewController.addRecipe()
        }
    }
       
    
    @IBAction func editTableView (sender:UIBarButtonItem)
    {
        guard let tableViewController = children.first as? RecipeListController else  {
           fatalError("Check storyboard for missing RecipeListController")
         }
        
        if tableViewController.isEditing {
            tableViewController.setEditing(false, animated: true);
            sender.title = "Edit";
            cancelButton.image = UIImage(named: "plus")

            RecipeStore.shared.saveItemsToCache()
            NotificationCenter.default.post(name: Notification.Name.ReloadAllTabs, object: self)
        }
        else{
            tableViewController.setEditing(true, animated: true);
            sender.title = "Save";
            cancelButton.image = nil
                
        }
    }
}

class RecipeListController: UITableViewController
{
    
    @IBAction func handleLongTap(recognizer:UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if (tableView.isEditing) {
                return
            }
            
            let addNew = UIAlertController(title: "Add", message: "Add new recipe", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Yes", style: .default, handler: { alert -> Void in
                self.addRecipe()
            })
            
            let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: { (action : UIAlertAction!) -> Void in })
            
            addNew.addAction(okAction)
            addNew.addAction(cancelAction)
            
            self.present(addNew, animated: true, completion: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
     
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true // Yes, the table view can be reordered
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = RecipeStore.shared.items[fromIndexPath.row]
        RecipeStore.shared.items.remove(at:fromIndexPath.row)
        RecipeStore.shared.items.insert(item, at: destinationIndexPath.row)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for cell in tableView.visibleCells {
               if tableView.indexPath(for: cell)!.row < 4 {
                   UIView.animate(withDuration: 0.3, animations: {
                       cell.textLabel?.textColor = UIColor.sourdough
                   })
               } else {
                   UIView.animate(withDuration: 0.3, animations: {
                       cell.textLabel?.textColor = UIColor.black
                   })
               }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
        {
            let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (action, view, handler) in
                RecipeStore.shared.items.remove(at: indexPath.row)
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.tableView.endUpdates()
            }
            deleteAction.backgroundColor = UIColor.red

            if tableView.isEditing {
                return UISwipeActionsConfiguration(actions: [deleteAction])
            } else {
               return UISwipeActionsConfiguration(actions: [])
            }
        }
     
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 3 {
            let item = RecipeStore.shared.items[indexPath.row]
            RecipeStore.shared.items.remove(at:indexPath.row)
            RecipeStore.shared.items.insert(item, at: 3)
            RecipeStore.shared.saveItemsToCache()
            NotificationCenter.default.post(name: Notification.Name.ReloadAllTabs, object: self, userInfo: ["tab": 3])
        }
    }
    
   
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RecipeStore.shared.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as? RecipeCell  else {
            fatalError("The dequeued cell is not an instance of RecipeCell.")
        }
        
        let recipe = RecipeStore.shared.items[indexPath.row]
        
        cell.textLabel?.text = recipe.name
        if indexPath.row < 4 {
            cell.textLabel?.textColor = UIColor.sourdough
        } else {
            cell.textLabel?.textColor = UIColor.black
        }
        
        return cell
    }

    func addRecipe(){
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let nr = RecipeItem.empty()
        nr.name = "new"
        
        if let clip = UIPasteboard.general.string {
            if clip.starts(with: externalDomain) {
                nr.link =  GithubStorage.paramsOnly(clip)
                nr.name = "pasted"
            }
        }

        RecipeStore.shared.items.append(nr)
        RecipeStore.shared.saveItemsToCache()
        
       NotificationCenter.default.post(name: Notification.Name.ReloadAllTabs, object: self)
    }
}


class RecipeCell: UITableViewCell{
    
    
}
