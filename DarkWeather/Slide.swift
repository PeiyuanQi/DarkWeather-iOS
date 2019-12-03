//
//  Slide.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/11/25.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit
import Toast_Swift

@objc protocol favListDelegate {
    func updateFav()
}


class Slide: UIView {
    var ifFaved = false
    var cityFullName = ""
    var favListDelegate: favListDelegate?
    var lat : String = ""
    var lng : String = ""
    var cityCardData = cityCardDataStruct()
    
    struct cityCardDataStruct {
        var weatherIconStr : String = ""
        var weatherSummary : String = ""
        var tempStr : String = ""
        var cityName : String = ""
        var humidity = ""
        var windSpeed = ""
        var visibility = ""
        var pressure = ""
        var weeklySummaryInFav = ""
        var weeklyIconInFav = ""
        var arrayOfWeeklyCellDataInFav : [weeklyCellData] = []
        var currentWeatherInFav : [String:Any] = [:]
        var weeklyWeatherDataInFav : [[String:Any]] = []
    }
    
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var weatherCardView: UIView!
    @IBOutlet weak var fourDataView: UIView!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var visibilityLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var weeklyTableView: UITableView!
    @IBAction func favButton(_ sender: Any) {
        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
        if favList == nil {
            favList = []
        }
        print("before click favlist: ",favListStr)
        if ifFaved {
            // delete fav
            favList = favList?.filter {$0 != self.cityFullName}
            let dataToStore = (try? JSONEncoder().encode(favList)) ?? nil
            let stringToStore = String(data: dataToStore!, encoding: .utf8)
            UserDefaults.standard.set(stringToStore, forKey: "favList")
            
            favButtonOutlet.setImage(UIImage(named: "plus-circle"), for: .normal)
//            print("after click favlist: ",stringToStore)
            // update slides
            favListDelegate?.updateFav()
            ifFaved = false
            self.makeToast((self.locationLabel.text ?? "Default") + " was removed from the Favorite List")
            
        } else {
            // add fav, means in detail controller
            favList?.append(self.cityFullName)
            let dataToStore = (try? JSONEncoder().encode(favList)) ?? nil
            let stringToStore = String(data: dataToStore!, encoding: .utf8)
            UserDefaults.standard.set(stringToStore, forKey: "favList")
            
            favButtonOutlet.setImage(UIImage(named: "trash-can"), for: .normal)
//            print("after click favlist: ",stringToStore)
            favListDelegate?.updateFav()
            ifFaved = true
            self.makeToast((self.locationLabel.text ?? "Default") + " was added to the Favorite List")
        }
    }
    @IBOutlet weak var favButtonOutlet: UIButton!
    
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
        
        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
//        print("favlist: ",favListStr)
        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
        if favList == nil {
            favList = []
        }
        if favList!.contains(self.cityFullName) {
            ifFaved = true
            // already faved
            favButtonOutlet.setImage(UIImage(named: "trash-can"), for: .normal)
//            print("fav btn trash: ", cityFullName)
        } else {
            ifFaved = false
            // not faved
            favButtonOutlet.setImage(UIImage(named: "plus-circle"), for: .normal)
//            print("fav btn add: ", cityFullName)
        }
        
        
        self.weatherCardView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        
        self.weatherCardView.layer.cornerRadius = 5
        self.weatherCardView.layer.masksToBounds = true
        self.weatherCardView.layer.borderWidth = 1
        self.weatherCardView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.fourDataView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    }

}
