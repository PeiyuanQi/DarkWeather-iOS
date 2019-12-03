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


class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, favListDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return curLocArrayOfWeeklyCellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCellFromNib", for: indexPath) as! WeeklyTableViewCell
        cell.weatherImgView.image = UIImage(named: curLocArrayOfWeeklyCellData[indexPath.row].weatherIconStr)
        cell.dateLabel.text = curLocArrayOfWeeklyCellData[indexPath.row].dateStr
        cell.sunriseTimeLabel.text = curLocArrayOfWeeklyCellData[indexPath.row].sunriseTimeStr
        cell.sunsetTimeLabel.text = curLocArrayOfWeeklyCellData[indexPath.row].sunsetTimeStr
        return cell
    }
    
    @IBOutlet weak var weatherView: UIView!
    @IBAction func twitterBtn(_ sender: Any) {
        let textString = "The current temperature at " + self.city + " is " + self.currentTempStr + ". The weather conditions are " + self.currentSummary + " #CSCI571WeatherSearch"
        guard let url = URL(string: "https://twitter.com/intent/tweet?text=" + textString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) else {return}
        UIApplication.shared.open(url)

    }
    
    struct weeklyCellData {
        var weatherIconStr:String
        var dateStr:String
        var sunsetTimeStr:String
        var sunriseTimeStr:String
    }
    
    var city = ""
    
    var slideView = Slide()
    var cityString = ""
    var currentWeatherInfo : [String: Any] = [:]
    var weeklyWeatherInfo : [String: Any] = [:]
    var currentTempStr = "", currentSummary = "", currentIcon = "", currentHumidity = "", currentWindSpeed = "", currentVisibility = "", currentPressure = ""
    var weeklySummary = "", weeklyIcon = ""
    var weeklyData:[[String:Any]] = []
    var curLocArrayOfWeeklyCellData:[weeklyCellData] = []

    
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
        self.slideView.weatherIcon.image = UIImage(named: summaryIconMap[self.currentIcon] ?? "weather-sunny")
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
                    weatherIconStr: summaryIconMap[self.weeklyData[i]["icon"] as! String] ?? "clear-day",
                    dateStr: self.translateDate(timestamp: self.weeklyData[i]["time"] as! TimeInterval),
                    sunsetTimeStr: self.translatePST(timestamp: self.weeklyData[i]["sunsetTime"] as! TimeInterval),
                    sunriseTimeStr: self.translatePST(timestamp: self.weeklyData[i]["sunriseTime"] as! TimeInterval)
                )
                curLocArrayOfWeeklyCellData.append(currentCell)
            }
            
            print(curLocArrayOfWeeklyCellData.count)
            slideView.weeklyTableView.reloadData()
            
            return
            
        }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        print("handleTapInDetail")
        performSegue(withIdentifier: "showTabFromDetail", sender: self)
    }
    

    func updateFav() {
        
        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
        if favList == nil {
            favList = []
        }
        // check cities in slides are needed, delete not needed
        var itIndex = 1
        while itIndex < slides.count {
            if (favList?.contains(slides[itIndex].cityFullName))! == false && slides[itIndex].ifFaved == true {
                print("remove slide at ", itIndex)
                // first remove current subview from scrollview
                slides[itIndex].removeFromSuperview()
                // then remove from slides[]
                slides.remove(at: itIndex)
                itIndex -= 1
            }
            favList = favList?.filter { $0 != slides[itIndex].cityFullName}
            itIndex += 1
        }
        // rest cities in favlist are new and will be added into slides
        var curIndex = slides.count
        for eachFullName in favList! {
            // add new city to slides
            let curSlide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
            curSlide.locationLabel.text = String(eachFullName.split(separator: ",").first!)
            curSlide.cityFullName = eachFullName
            // Set up slide data
            // MARK: todo
            curSlide.lat = self.clickedLat
            curSlide.lng = self.clickedLng
            curSlide.ifFaved = true
            // rest data will be populated in SearchBarViewController viewwillappear
            // add current new slide to slides
            slides.append(curSlide)
            curIndex += 1
//            print("current slides num, from updatefav: ", slides.count)
        }
    }
    
    var clickedLat = ""
    var clickedLng = ""
    
    override func viewDidLoad() {
        city = String(self.cityString.split(separator: ",").first!)
        SwiftSpinner.show("Fetching Weather Details for " + city + "...")
        super.viewDidLoad()
        
        self.title = city
        
        slideView = (Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as? Slide)!
        self.weatherView.addSubview(slideView)
        
        slideView.translatesAutoresizingMaskIntoConstraints = true
        slideView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        slideView.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        slideView.weeklyTableView.delegate = self
        slideView.weeklyTableView.dataSource = self
        slideView.weeklyTableView.register(UINib(nibName: "WeeklyTableViewCell", bundle: nil), forCellReuseIdentifier: "WeeklyCellFromNib")
        
        slideView.locationLabel.text = city
        
        slideView.cityFullName = cityString
        
        slideView.favListDelegate = self
        
        // segue detect for detail tabs
        let tapOnCard = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        slideView.weatherCardView.addGestureRecognizer(tapOnCard)
        slideView.weeklyTableView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        slideView.weeklyTableView.layer.cornerRadius = 5
        slideView.weeklyTableView.layer.borderWidth = 1
        slideView.weeklyTableView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        

        
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
            self.clickedLat = String(format:"%.4f", value["lat"] as! Double)
            self.clickedLng = String(format:"%.4f", value["lng"] as! Double)
            
            
            let weatherURL = "http://webhw9-12345.appspot.com/weather/currently"
            
            print("clickedlng: ",self.clickedLng)
            print("clickedlng: ",self.clickedLat)
            
            Alamofire.request(weatherURL,
                      method: .get,
                      parameters: ["lat": self.clickedLat,
                                   "lng": self.clickedLng])
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
//                print(self.currentWeatherInfo)
                self.currentWeatherCallback(currentJsonObj: self.currentWeatherInfo)
//                print(self.weeklyWeatherInfo)
                self.weeklyWeatherCallback(weekJsonObj: self.weeklyWeatherInfo)
                SwiftSpinner.hide()
                
            }
        }
        

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is TabBarViewController {
            let vc = segue.destination as? TabBarViewController
            vc?.cityName = self.city
            vc?.weeklyData = self.weeklyData
            vc?.weeklyIcon = self.weeklyIcon
            vc?.weeklySummary = self.weeklySummary
            vc?.weatherIconStr = summaryIconMap[self.currentIcon]!
            vc?.weatherSummary = self.currentSummary
            vc?.windSpeed = String(round(self.currentWeatherInfo["windSpeed"] as! Double * 100) / 100) + " mph"
            vc?.pressure = String(round(self.currentWeatherInfo["pressure"] as! Double * 100) / 100) + " mb"
            vc?.precipitation = String(round(self.currentWeatherInfo["precipIntensity"] as! Double * 100) / 100) + " mmph"
            vc?.temperature = String(format:"%.0f",round(self.currentWeatherInfo["temperature"] as! Double )) + "°F"
            vc?.humidity = String(round(self.currentWeatherInfo["humidity"] as! Double * 100) / 100) + " %"
            vc?.visibility = String(round(self.currentWeatherInfo["visibility"] as! Double * 100) / 100) + " km"
            vc?.cloudCover = String(round(self.currentWeatherInfo["cloudCover"] as! Double * 100) / 100) + " %"
            vc?.ozone = String(round(self.currentWeatherInfo["ozone"] as! Double * 100) / 100) + " DU"
        }
    }
    
    
    

}
