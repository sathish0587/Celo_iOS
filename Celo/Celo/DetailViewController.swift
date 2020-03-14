//
//  DetailViewController.swift
//  Celo
//
//  Created by Sathish Kumar on 12/03/20.
//  Copyright © 2020 Sathish Kumar. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var userDataModel = UserDataModel()
    var id: String = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "User Details"
        self.getImage()
        self.nameLabel.text = String(format:"Name: %@", self.userDataModel.name ?? "")
        self.emailLabel.text = String(format:"Email: %@", self.userDataModel.email ?? "")
        self.phoneLabel.text = String(format:"Phone: %@", self.userDataModel.phone ?? "")
        self.locationLabel.text = String(format:"Location: %@", self.userDataModel.location ?? "")


        // Do any additional setup after loading the view.
    }
    func getImage(){
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // choose a name for your image
        let fileName = String(format: "%@.jpg", self.id)
        // create the destination file url to save your image
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        // get your UIImage jpeg data representation and check if the destination file url already exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            self.imageView.image = UIImage(contentsOfFile: fileURL.path)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
