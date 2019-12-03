//
//  TabBarViewController.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/12/1.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    @IBAction func twitterShare(_ sender: Any) {
        
        let textString = "The current temperature at " + self.cityName + " is " + self.temperature + ". The weather conditions are " + self.weatherSummary + " #CSCI571WeatherSearch"
        guard let url = URL(string: "https://twitter.com/intent/tweet?text=" + textString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) else {return}
        UIApplication.shared.open(url)
    }
    var currentWeather:[String:Any] = [:]
    var weeeklyWeather:[String:Any] = [:]
    
    var weeklyIcon = ""
    var weeklySummary = ""
    var weeklyData : [[String:Any]] = []
    
    var cityName = ""
    
    var windSpeed = ""
    var pressure = ""
    var precipitation = ""
    var temperature = ""
    var weatherIconStr = ""
    var weatherSummary = ""
    var humidity = ""
    var visibility = ""
    var cloudCover = ""
    var ozone = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.cityName
        
        let todayTab = self.viewControllers![0] as! TodayViewController
        todayTab.windSpeed = self.windSpeed
        todayTab.pressure = self.pressure
        todayTab.precipitation = self.precipitation
        todayTab.temperature = self.temperature
        todayTab.humidity = self.humidity
        todayTab.visibility = self.visibility
        todayTab.cloudCover = self.cloudCover
        todayTab.ozone = self.ozone
        
        todayTab.weatherIconStr = self.weatherIconStr
        todayTab.weatherSummary = self.weatherSummary
        
        let weeklyTab = self.viewControllers![1] as! WeeklyViewController
        
        
        for i in 0 ..< weeklyData.count {
            var tmpPair:[Double] = []
            let minTemp = weeklyData[i]["temperatureLow"]
            let maxTemp = weeklyData[i]["temperatureHigh"]
            tmpPair.append((round(minTemp as! Double) * 10) / 10)
            tmpPair.append((round(maxTemp as! Double) * 10) / 10)
            weeklyTab.minmaxWeeklyData.append(tmpPair)
        }
        weeklyTab.weeklySummary = self.weeklySummary
        weeklyTab.weeklyIcon = self.weeklyIcon
        
        let photoTab = self.viewControllers![2] as! PhotoViewController
        photoTab.cityName = self.cityName

        // Do any additional setup after loading the view.
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
