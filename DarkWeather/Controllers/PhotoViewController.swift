//
//  PhotoViewController.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/12/1.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit
import SwiftSpinner
import Alamofire

class PhotoViewController: UIViewController {
    @IBOutlet weak var photoScrollView: UIScrollView!
    
    var cityName : String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftSpinner.show("Fetching Google Images...")
        let imageURL = "http://webhw9-12345.appspot.com/googleImage"
        Alamofire.request(imageURL,
                  method: .get,
                  parameters: ["cityname": self.cityName])
        .validate()
        .responseJSON { response in
            guard response.result.isSuccess else {
                print("Error while fetching image.")
                return
            }

            guard let value = response.result.value as? [String] else {
                print("Malformed data received from image service")
                return
            }
            
            self.showImages(listOfURL: value)
            
        }
        

        // Do any additional setup after loading the view.
    }
    
    func imageGet(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    var width:CGFloat = 394.0
    var height:CGFloat = 500.0
    var startPos:CGFloat = 0.0
    var photoScrollViewHeight:CGFloat = 0.0
    var imageArray : [UIImage] = []
    var requiredImg = 8
    
    func showImages(listOfURL : [String]) {
        for urlStr in listOfURL{
            let index = urlStr.index(urlStr.startIndex, offsetBy: 4)
            if urlStr[index] != "s" {
                print("not https pic, dropped", urlStr)
                self.requiredImg -= 1
                continue
            }
            let url = URL(string: urlStr)
            self.imageGet(from: url!) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async() {
                    
                    self.imageArray.append(UIImage(data: data)!)
                    if self.imageArray.count >= self.requiredImg {
                        print("process image into scroll")
                        for eachImage in self.imageArray {
                            let imgView = UIImageView(image: eachImage)
                            imgView.frame.size.width = self.width
                            imgView.frame.size.height = self.height
                            imgView.contentMode = UIView.ContentMode.scaleAspectFill
                            imgView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                            imgView.center = self.view.center
                            imgView.frame.origin.y = self.startPos
                            print("start y: ", self.startPos)
                            imgView.frame.origin.x = CGFloat(0.0)
                            self.photoScrollView.addSubview(imgView)
                            
                            self.startPos += self.height
                            self.photoScrollViewHeight += self.height
                            self.photoScrollView.contentSize.height = self.photoScrollViewHeight
                        }
                        SwiftSpinner.hide()
                        
                    }

                }
            }
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
