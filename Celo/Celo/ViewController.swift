//
//  ViewController.swift
//  Celo
//
//  Created by Sathish Kumar on 12/03/20.
//  Copyright © 2020 Sathish Kumar. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var userDataModel : [UserDataModel] = []
    var fetchController: NSFetchedResultsController<UserInfo>?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var users: [UserInfo] = []
    var limit = 10
//    let totalEnteries = 100
    var recordsArray:[Int] = Array()

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "List of Users"
        var index = 0
        while index < self.limit {
            self.recordsArray.append(index)
            index = index + 1
        }
        let context = appDelegate.persistentContainer.viewContext
        self.showActivityIndicator()

        ServiceManager.sharedInstance.getUserInformation(onSuccess: { UserDataModel in
            self.userDataModel = UserDataModel
            
            self.deleteAllRecords()
            
            if UserDataModel.count > 0 {
                for (index, data) in UserDataModel.enumerated() {
                    let userEntity = NSEntityDescription.entity(forEntityName: "UserInfo", in: context)
                    let user = UserInfo(entity: userEntity!, insertInto: context)
                    user.name = data.name
                    user.dob = data.dob
                    user.gender = data.gender
                    user.thumbnailURL = data.thumbnailUrl
                    user.imageURL = data.largeImageUrl
                    user.email = data.email
                    user.phone = data.phone
                    user.location = data.location
                    user.index = Int16(index)
                    
                    self.users.append(user)
                }
                do {
                    try context.save()
                } catch {
                    print("Failed saving")
                }
            }
            DispatchQueue.main.async {
                self.hideActivityIndicator()
                self.tableView.reloadData()
            }
        }, onFailure: { error in
            DispatchQueue.main.async {
                self.hideActivityIndicator()
                self.fetchDataFromDB()
            }
          }
        )
    }
     //MARK: fetch data for offline use
    func fetchDataFromDB (){
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<UserInfo>(entityName: "UserInfo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]

        do {
            let result = try context.fetch(fetchRequest)
            
            if result.count > 0 {
                for data in result {
                    var dataModel =  UserDataModel()
                    dataModel.name = (data.value(forKey: "name") as? String)
                    dataModel.dob = (data.value(forKey: "dob") as? String)
                    dataModel.gender = (data.value(forKey: "gender") as? String)
                    dataModel.email = (data.value(forKey: "email") as? String)
                    dataModel.phone = (data.value(forKey: "phone") as? String)
                    dataModel.location = (data.value(forKey: "location") as? String)
                    dataModel.thumbnailUrl = (data.value(forKey: "thumbnailURL") as? String)
                    if data.value(forKey:"thumbnailImage") != nil {
                        dataModel.thumbnailImage = UIImage(data: (data.value(forKey:"thumbnailImage") as! Data))
                    }
                    dataModel.largeImageUrl = (data.value(forKey: "imageURL") as? String)

                    self.userDataModel.append(dataModel)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        } catch let error as NSError {
            print(error.description)
        }
        
    }
    //MARK: Delete old records
    func deleteAllRecords() {
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
        // delete saved images
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for fileURL in fileURLs {
                if fileURL.pathExtension == "jpg" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
    }
    //MARK: Load images from server
    func load_image(urlString:String, imageview:UIImageView, index:NSInteger)
    {
        if urlString.isEmpty {
            return
        }
        else {
            let imgURL: URL = URL(string: urlString)!
            let request: URLRequest = URLRequest(url: imgURL as URL)
            URLSession.shared.dataTask(with: request) {data, response, error in
                if (error == nil) {
                    self.userDataModel[index].thumbnailImage = UIImage(data: data!)
                    guard let thumbnailImage = self.userDataModel[index].thumbnailImage else{
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.saveThumbnailToDB(id: index,image: thumbnailImage)
                        imageview.image = self.userDataModel[index].thumbnailImage
                    }
                    
                } else {
                    DispatchQueue.main.async {
                    imageview.image = nil
                    }
                    print("Error : \(error?.localizedDescription ?? "other error")");
                }
                }.resume();
        }
        
    }
    //MARK: Save images
    func saveLargeImageToDB(urlString:String, index:NSInteger)
    {
        if urlString.isEmpty {
            return
        }
        else {
        let imgURL: URL = URL(string: urlString)!
        let request: URLRequest = URLRequest(url: imgURL as URL)
        URLSession.shared.dataTask(with: request) {data, response, error in
            if (error == nil) {
                let largeImage = UIImage(data: data!)
                // get the documents directory url
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                // choose a name for your image
                let fileName = String(format: "%d.jpg", index)
                // create the destination file url to save your image
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                // get your UIImage jpeg data representation and check if the destination file url already exists
                if let data = largeImage?.jpegData(compressionQuality:  1.0),
                    !FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        // writes the image data to disk
                        try data.write(to: fileURL)
                        print("file saved")
                    } catch {
                        print("error saving file:", error)
                    }
                }
                
            } else {
                print("Error : \(error?.localizedDescription ?? "other error")");
            }
            }.resume();
        }
        
    }
    
    func saveThumbnailToDB(id:Int,image:UIImage)
    {
        let context = appDelegate.persistentContainer.viewContext

        let newImageData = image.jpegData(compressionQuality: 1)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        fetchRequest.predicate = NSPredicate(format: "index = %i", id)
        
        do {
            let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject]
            if fetchResults?.count != 0{
                
                let managedObject = fetchResults?[0]
                managedObject?.setValue(newImageData, forKey: "thumbnailImage")

                do {
                    try context.save()
                } catch {
                    print("Failed saving")
                }
            }
        }catch let error as NSError {
            // something went wrong, print the error.
            print(error.description)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "DetailViewSegue") {
                if let indexPath = tableView.indexPathForSelectedRow{
                    if indexPath.row < self.userDataModel.count {
                    let viewController:DetailViewController = segue.destination as! DetailViewController
                    viewController.userDataModel = self.userDataModel[indexPath.row]
                    viewController.id = String(indexPath.row)
                }
            }
        }
    }
    
    //MARK: Tableview delegate and datasource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recordsArray.count//self.userDataModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UserInfoTableViewCell = tableView.dequeueReusableCell(withIdentifier: "CellData") as! UserInfoTableViewCell
        tableView.layer.cornerRadius = 10

        if indexPath.row < self.userDataModel.count {
            cell.nameLabel?.text = self.userDataModel[indexPath.row].name
            cell.genderLabel?.text = self.userDataModel[indexPath.row].gender
            cell.dobLabel?.text = self.userDataModel[indexPath.row].dob
            if ((self.userDataModel[indexPath.row].thumbnailImage) != nil)
            {
                cell.thumbnailImg?.image = self.userDataModel[indexPath.row].thumbnailImage
            }
            else
            {
                self.load_image(urlString: self.userDataModel[indexPath.row].thumbnailUrl ?? "", imageview: cell.thumbnailImg!, index: indexPath.row)
                self.saveLargeImageToDB(urlString: self.userDataModel[indexPath.row].largeImageUrl ?? "", index: indexPath.row)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == recordsArray.count - 1 {
            // we are at last cell load more content
            if recordsArray.count < self.userDataModel.count {
                // we need to bring more records as there are some pending records available
                var index = recordsArray.count
                limit = index + 10
                while index < limit {
                    recordsArray.append(index)
                    index = index + 1
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "DetailViewSegue", sender: self)
    }

}
// For activity indicator
extension UIViewController {
    func showActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        activityIndicator.backgroundColor = UIColor(red:0.16, green:0.17, blue:0.21, alpha:1)
        activityIndicator.layer.cornerRadius = 6
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .whiteLarge
        activityIndicator.startAnimating()
        
        activityIndicator.tag = 100
        
        for subview in view.subviews {
            if subview.tag == 100 {
                print("already added")
                return
            }
        }
        view.addSubview(activityIndicator)
    }
    func hideActivityIndicator() {
        let activityIndicator = view.viewWithTag(100) as? UIActivityIndicatorView
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
    }
}
