//
//  ServiceManager.swift
//  Celo
//
//  12/06/20.
//  Copyright © 2020 Sathish Kumar. All rights reserved.
//

import UIKit

class ServiceManager: NSObject {
    let baseURL = "https://randomuser.me/api/?results=1000"
    static let sharedInstance = ServiceManager()
    var userInfoModelArray = [UserDataModel]()

    func getUserInformation(onSuccess: @escaping([UserDataModel]) -> Void, onFailure: @escaping(Error) -> Void){
        let escapedUrlString = baseURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        guard let url = URL(string:escapedUrlString ?? "") else { return }
        let task = URLSession.shared.dataTask(with: url) {[weak self](data, response, error) in
            
            if error != nil {
                print("Client error!")
                onFailure(error!)
            }
            else{
                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    let serviceError: NSError = NSError(domain: "", code: 400, userInfo: nil)
                    onFailure(serviceError)
                    print("Server error!")
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    print(json as Any)
                    
                    if let jsonDictionary = json as [String : Any]? {
                        if let results = jsonDictionary["results"] as? NSArray {
                            for dict in results {
                                var dataModel =  UserDataModel()
                                if let resultDict = dict as? NSDictionary {
                                    if let name = resultDict["name"] as? NSDictionary{
                                        if let title = name["title"] as? String{
                                            dataModel.name = title
                                            if let first = name["first"] as? String{
                                                dataModel.name = dataModel.name! + " " + first
                                                if let last = name["last"] as? String{
                                                    dataModel.name = dataModel.name! + " " + last
                                                }
                                            }
                                        }
                                    }
                                    if let gender = resultDict["gender"] as? String{
                                        dataModel.gender = gender
                                    }
                                    if let email = resultDict["email"] as? String{
                                        dataModel.email = email
                                    }
                                    
                                    if let location = resultDict["location"] as? NSDictionary{
                                        if let city = location["city"] as? String{
                                        dataModel.location = city
                                        }
                                    }
                                    if let phone = resultDict["phone"] as? String{
                                        dataModel.phone = phone
                                    }
                                    if let dob = resultDict["dob"] as? NSDictionary{
                                        if let date = dob["date"] as? String{
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                                            if let dateValue = formatter.date(from: date){
                                                formatter.dateFormat = "dd-MM-YYYY"
                                                dataModel.dob = formatter.string(from: dateValue)
                                            }
                                        }
                                    }
                                    if let dob = resultDict["picture"] as? NSDictionary{
                                        if let thumbnail = dob["thumbnail"] as? String{
                                            dataModel.thumbnailUrl = thumbnail
                                        }
                                        if let largeImage = dob["large"] as? String{
                                            dataModel.largeImageUrl = largeImage
                                        }
                                    }
                                }
                                self?.userInfoModelArray.append(dataModel)
                            }
                        }
                    }
                
                    onSuccess(self?.userInfoModelArray ?? [] )
                    
                } catch {
                    print("JSONSerialization error:", error)
                }
            }
        }
        task.resume()
    }

}
