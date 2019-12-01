//
//  DetailViewController.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/11/30.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit
import Alamofire
import SwiftSpinner


class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfWeeklyCellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCellFromNib", for: indexPath) as! WeeklyTableViewCell
        cell.weatherImgView.image = UIImage(named: arrayOfWeeklyCellData[indexPath.row].weatherIconStr)
        cell.dateLabel.text = arrayOfWeeklyCellData[indexPath.row].dateStr
        cell.sunriseTimeLabel.text = arrayOfWeeklyCellData[indexPath.row].sunriseTimeStr
        cell.sunsetTimeLabel.text = arrayOfWeeklyCellData[indexPath.row].sunsetTimeStr
        return cell
    }
    
    @IBOutlet weak var weatherView: UIView!
    
    struct weeklyCellData {
        var weatherIconStr:String
        var dateStr:String
        var sunsetTimeStr:String
        var sunriseTimeStr:String
    }
    
    var slideView = Slide()
    var cityString = ""
    var currentWeatherInfo : [String: Any] = [:]
    var weeklyWeatherInfo : [String: Any] = [:]
    var currentTempStr = "", currentSummary = "", currentIcon = "", currentHumidity = "", currentWindSpeed = "", currentVisibility = "", currentPressure = ""
    var weeklySummary = "", weeklyIcon = ""
    var weeklyData:[[String:Any]] = []
    var arrayOfWeeklyCellData:[weeklyCellData] = []
    let summaryIconMap = [
        "clear-day": "weather-sunny",
        "clear-night" : "weather-night",
        "rain" : "weather-rainy",
        "sleet" : "weather-snowy-rainy",
        "snow" : "weather-snowy",
        "wind" : "weather-windy-variant",
        "fog" : "weather-fog",
        "cloudy" : "weather-cloudy",
        "partly-cloudy-night" : "weather-night-partly-cloudy",
        "partly-cloudy-day" : "weather-partly-cloudy",
    ]
    
    func currentWeatherCallback(currentJsonObj: [String:Any]?) -> Void{
    //        print(currentJsonObj!)
            
            self.currentTempStr = String(format:"%.0f", currentJsonObj?["temperature"] as! Double) + "°F"
            self.currentSummary = currentJsonObj?["summary"] as! String
            self.currentIcon = currentJsonObj?["icon"] as! String
            self.currentHumidity = String(format: "%.1f", round(currentJsonObj?["humidity"] as! Double * 1000 / 10)) + " %"
            self.currentWindSpeed = String(format: "%.2f", currentJsonObj?["windSpeed"] as! Double) + " mph"
            self.currentVisibility = String(currentJsonObj?["visibility"] as! Double) + " km"
            self.currentPressure = String(currentJsonObj?["pressure"] as! Double) + " mb"
                
            self.slideView.tempLabel.text = self.currentTempStr
            self.slideView.summaryLabel.text = self.currentSummary
            self.slideView.humidityLabel.text = self.currentHumidity
            self.slideView.windSpeedLabel.text = self.currentWindSpeed
            self.slideView.visibilityLabel.text = self.currentVisibility
            self.slideView.pressureLabel.text = self.currentPressure
            self.slideView.weatherIcon.image = UIImage(named: self.summaryIconMap[self.currentIcon] ?? "weather-sunny")
            print("Finish Current Callback")
            
            return
        }
    
    func translateDate(timestamp: TimeInterval) -> String{
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let returnDate = dateFormatter.string(from: date)
        return returnDate
    }
    
    func translatePST(timestamp: TimeInterval) -> String{
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "HH:mm"
        let returnDate = dateFormatter.string(from: date)
        return returnDate
    }
    
    func weeklyWeatherCallback(weekJsonObj: [String:Any]?) -> Void{
    //        print(weekJsonObj!)
            
            self.weeklySummary = weekJsonObj?["summary"] as! String
            self.weeklyIcon = weekJsonObj?["icon"] as! String
            
            self.weeklyData = weekJsonObj?["data"] as! [[String:Any]]
            
            for i in 0 ... 7 {
                let currentCell = weeklyCellData(
                    weatherIconStr: self.summaryIconMap[self.weeklyData[i]["icon"] as! String] ?? "clear-day",
                    dateStr: self.translateDate(timestamp: self.weeklyData[i]["time"] as! TimeInterval),
                    sunsetTimeStr: self.translatePST(timestamp: self.weeklyData[i]["sunsetTime"] as! TimeInterval),
                    sunriseTimeStr: self.translatePST(timestamp: self.weeklyData[i]["sunriseTime"] as! TimeInterval)
                )
                arrayOfWeeklyCellData.append(currentCell)
            }
            
            print(arrayOfWeeklyCellData.count)
            slideView.weeklyTableView.reloadData()
            
            return
            
        }
    
    override func viewDidLoad() {
        let city = String(self.cityString.split(separator: ",").first!)
        SwiftSpinner.show("Fetching Weather Details for " + city + "...")
        super.viewDidLoad()
        
        
        slideView = (Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as? Slide)!
        self.weatherView.addSubview(slideView)
        
        slideView.translatesAutoresizingMaskIntoConstraints = true
        slideView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        slideView.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        slideView.weeklyTableView.delegate = self
        slideView.weeklyTableView.dataSource = self
        slideView.weeklyTableView.register(UINib(nibName: "WeeklyTableViewCell", bundle: nil), forCellReuseIdentifier: "WeeklyCellFromNib")
        
        slideView.locationLabel.text = city
        
        
        var clickedLat = ""
        var clickedLng = ""
        
        let geoURL = "http://webhw9-12345.appspot.com/latlng"
        Alamofire.request(geoURL,
                  method: .get,
                  parameters: ["address": self.cityString as Any])
        .validate()
        .responseJSON { response in
            guard response.result.isSuccess else {
                print("Error while fetching weather: (String(describing: response.result.error)")
                return
            }

            guard let value = response.result.value as? [String: Any] else {
                print("Malformed data received from getCurrentlyWeekly service")
                return
            }
            clickedLat = String(format:"%.4f", value["lat"] as! Double)
            clickedLng = String(format:"%.4f", value["lng"] as! Double)
            
            
            let weatherURL = "http://webhw9-12345.appspot.com/weather/currently"
            
            print("clickedlng: ",clickedLng)
            print("clickedlng: ",clickedLat)
            
            Alamofire.request(weatherURL,
                      method: .get,
                      parameters: ["lat": clickedLat,
                                   "lng": clickedLng])
            .validate()
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("Error while fetching weather: (String(describing: response.result.error)")
                    return
                }

                guard let value = response.result.value as? [String: Any] else {
                    print("Malformed data received from getCurrentlyWeekly service")
                    return
                }
                
                self.currentWeatherInfo = value["currently"] as? [String: Any] ?? [:]
                self.weeklyWeatherInfo = value["daily"] as? [String: Any] ?? [:]
                
                // set display info
                print(self.currentWeatherInfo)
                self.currentWeatherCallback(currentJsonObj: self.currentWeatherInfo)
                print(self.weeklyWeatherInfo)
                self.weeklyWeatherCallback(weekJsonObj: self.weeklyWeatherInfo)
                SwiftSpinner.hide()
                
            }
        }
        

        // Do any additional setup after loading the view.
    }
    
    
    

}
