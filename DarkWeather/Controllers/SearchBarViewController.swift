//
//  SearchBarViewController.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/11/25.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import Alamofire

class SearchBarViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    struct weeklyCellData {
        var weatherIconStr:String
        var dateStr:String
        var sunsetTimeStr:String
        var sunriseTimeStr:String
    }

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var weatherPageScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    var locastionList = ["a", "b"]
    var currentWeatherControllerIndex = 0
    var slides:[Slide] = []
    var currentCityStr = ""
    var currentTempStr = ""
    var currentSummary = ""
    var currentIcon = "clear-day"
    var currentHumidity = ""
    var currentWindSpeed = ""
    var currentVisibility = ""
    var currentPressure = ""
    var weeklySummary = ""
    var weeklyIcon = "clear-day"
    var weeklyData:[[String: Any]] = []
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
    
    // Related to get current location
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
        
        
        weatherPageScrollView.delegate = self
        
        slides = createSlides()
        setupSlideScrollView(slides: slides)
        
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        view.bringSubviewToFront(pageControl)
        
        
//        for i in 0..<arrayOfWeeklyCellData.count {
//            slides[i].weeklyTableView.dataSource = self
//            slides[i].weeklyTableView.delegate = self
//        }
  
        slides[0].weeklyTableView.register(UINib(nibName: "WeeklyTableViewCell", bundle: nil), forCellReuseIdentifier: "WeeklyCellFromNib")
        slides[0].weeklyTableView.dataSource = self
        slides[0].weeklyTableView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestLocation()
        
        slides[0].weeklyTableView.reloadData()

    }
    
    // START related to slides
    func createSlides() -> [Slide] {

        let slide1:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        
        let slide2:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide2.locationLabel.text = "A real-life second view"
        
        
        return [slide1, slide2]
    }
    
    func setupSlideScrollView(slides : [Slide]) {
        weatherPageScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        weatherPageScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
        weatherPageScrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            if i == 0 {
                slides[i].favButtonOutlet.isHidden = true
            }
            weatherPageScrollView.addSubview(slides[i])
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
            pageControl.currentPage = Int(pageIndex)
            
            
            /*
             * below code changes the background color of view on paging the scrollview
             */
    //        self.scrollView(scrollView, didScrollToPercentageOffset: percentageHorizontalOffset)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setupSlideScrollView(slides: slides)
    }
    // END Slides related
    
    
    // START Location Related
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager?.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        getCurrentLocation(locations: locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print("error:: \(error.localizedDescription)")
    }
    
    func currentWeatherCallback(currentJsonObj: [String:Any]?) -> Void{
//        print(currentJsonObj!)
        
        self.currentTempStr = String(format:"%.0f", currentJsonObj?["temperature"] as! Double) + "°F"
        self.currentSummary = currentJsonObj?["summary"] as! String
        self.currentIcon = currentJsonObj?["icon"] as! String
        self.currentHumidity = String(format: "%.1f", round(currentJsonObj?["humidity"] as! Double * 1000 / 10)) + " %"
        self.currentWindSpeed = String(format: "%.2f", currentJsonObj?["windSpeed"] as! Double) + " mph"
        self.currentVisibility = String(currentJsonObj?["visibility"] as! Double) + " km"
        self.currentPressure = String(currentJsonObj?["pressure"] as! Double) + " mb"
            
        self.slides[0].tempLabel.text = self.currentTempStr
        self.slides[0].summaryLabel.text = self.currentSummary
        self.slides[0].humidityLabel.text = self.currentHumidity
        self.slides[0].windSpeedLabel.text = self.currentWindSpeed
        self.slides[0].visibilityLabel.text = self.currentVisibility
        self.slides[0].pressureLabel.text = self.currentPressure
        self.slides[0].weatherIcon.image = UIImage(named: self.summaryIconMap[self.currentIcon] ?? "weather-sunny")
        print("Finish Current Callback")
        
        return
    }
    
    //todo to finish translate
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
        slides[0].weeklyTableView.reloadData()
        
        return
        
    }
    
    func getCurrentLocation(locations: [CLLocation]) {
        print("Getting location")
        let lastCoord = locations.last
        if (lastCoord != nil) {
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastCoord!,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    // successfully get location
                    let firstLocation = placemarks?[0]
                    self.currentCityStr = firstLocation?.locality ?? "No Location"
                    self.slides[0].locationLabel.text = self.currentCityStr
                    print("location: " + (firstLocation?.locality ?? "No Location"))
                    
                    // make weather call
                    let weatherClient = WeatherRequest()
                    weatherClient.setLat(thislat: String(format: "%.8f", lastCoord?.coordinate.latitude ?? "0.0"))
                    weatherClient.setLng(thislng: String(format: "%.8f", lastCoord?.coordinate.longitude ?? "0.0"))
                    weatherClient.getCurrentlyWeekly(handleCurrently: self.currentWeatherCallback, handleWeekly: self.weeklyWeatherCallback)
                    
                    
                }
                else {
                 // An error occurred during geocoding.
                    print("error:: get location failed, the return value of geocoding is nil")
                }
            })
        }
        else {
            // No location was available.
            print("error:: get location failed, the return value of lManager is nil")
        }
    }
    
    // END of get current location
    
    
    
    // ****************
    // Weekly Table View Override
    // ****************
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("tell table: " + String(arrayOfWeeklyCellData.count))
        return arrayOfWeeklyCellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = Bundle.main.loadNibNamed("WeeklyTableViewCell", owner: self, options: nil)?.first as! WeeklyTableViewCell
        print("cellForRowAt")
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCellFromNib", for: indexPath) as! WeeklyTableViewCell
        cell.weatherImgView.image = UIImage(named: arrayOfWeeklyCellData[indexPath.row].weatherIconStr)
        cell.dateLabel.text = arrayOfWeeklyCellData[indexPath.row].dateStr
        cell.sunriseTimeLabel.text = arrayOfWeeklyCellData[indexPath.row].sunriseTimeStr
        cell.sunsetTimeLabel.text = arrayOfWeeklyCellData[indexPath.row].sunsetTimeStr
        return cell
    }
    
    // END of weekly table view override
    
    
    
    
    
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    

    

}


// ******************
// Data Model for URL Request
// ******************

class WeatherRequest{
    let baseURL = "http://localhost:3000/weather/"
    var lat:String, lng:String
    
    var onDataUpdate: ((_ data: String) -> Void)?

    
    init() {
        self.lat = ""
        self.lng = ""
    }
    
    func setLat(thislat:String) {
        self.lat = thislat
    }
    
    func setLng(thislng:String){
        self.lng = thislng
    }
    
    func getCurrentlyWeekly(handleCurrently: @escaping ([String:Any]?) -> Void, handleWeekly: @escaping ([String:Any]?) -> Void) {
        guard let url = URL(string: baseURL + "currently") else {
            handleCurrently(nil)
            return
        }
        Alamofire.request(url,
                  method: .get,
                  parameters: ["lat": self.lat,
                               "lng": self.lng])
        .validate()
        .responseJSON { response in
            guard response.result.isSuccess else {
                print("Error while fetching remote rooms: (String(describing: response.result.error)")
                handleCurrently(nil)
                return
            }

            guard let value = response.result.value as? [String: Any] else {
                print("Malformed data received from getCurrentlyWeekly service")
                handleCurrently(nil)
                return
            }
            
            let currentWeatherInfo = value["currently"] as? [String: Any]
            handleCurrently(currentWeatherInfo)
            let weeklyWeatherInfo = value["daily"] as? [String: Any]
            handleWeekly(weeklyWeatherInfo)
        }
    }
    
}
