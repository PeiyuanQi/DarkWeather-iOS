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
import SwiftSpinner

// MARK: GLOBAL VAR, WHICH SHOULD NOT EXIST
var slides:[Slide] = []
struct weeklyCellData {
    var weatherIconStr:String
    var dateStr:String
    var sunsetTimeStr:String
    var sunriseTimeStr:String
}
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
}
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


class SearchBarViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, favListDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var weatherPageScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var autoCompleteTableView: UITableView!
    
    var slide0CityStr = ""
    var slide0TempStr = ""
    var slide0WeatherSummary = ""
    var slide0WeatherIcon = "clear-day"
    var slide0Humidity = ""
    var slide0WindSpeed = ""
    var slide0Visibility = ""
    var slide0Pressure = ""
    var slide0weeklySummary = ""
    var slide0weeklyIcon = "clear-day"
    var slide0weeklyData:[[String: Any]] = []
    var curLocArrayOfWeeklyCellData:[weeklyCellData] = []
    var slide0Weather : [String:Any] = [:]
    var currentCityStr = "", currentWeeklyIcon = "", currentWeeklySummary = "", currentWeatherIcon = "", currentWeatherSummary = ""
    var currentWeeklyData : [[String : Any]] = []
    var currentWeather : [String : Any] = [:]
    
    var cityList:[String] = []{
       didSet {
          if cityList.count > 0 {
            autoCompleteTableView.isHidden = false
            autoCompleteTableView.reloadData()
          } else {
             autoCompleteTableView.isHidden = true
          }
       }
    }
    var selectedCityStr = ""
    

    

    
    // Related to get current location
    var locationManager: CLLocationManager?

    
    func updateFav() {
        // update fav in search bar view controller could only delete city, not able to add
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
                self.weatherPageScrollView.makeToast((slides[itIndex].locationLabel.text ?? "Default") + " was removed from the Favorite List")
                // then remove from slides[]
                slides.remove(at: itIndex)
                // update page control
                pageControl.numberOfPages = slides.count
                pageControl.currentPage = itIndex - 1
                // set focused subview to previous one
                weatherPageScrollView.setContentOffset(CGPoint(x: (itIndex - 1) * 414, y: 0), animated: true)
                itIndex -= 1
            }
            favList = favList?.filter { $0 != slides[itIndex].cityFullName}
            itIndex += 1
        }
        pageControl.numberOfPages = slides.count
        // no condition to add to fav in searchbarcontroller, so comment out
        view.bringSubviewToFront(pageControl)
        setupSlideScrollView(slides: slides)
    }

    func storeWeeklyWeatherForFavCities(weekJsonObj : [String : Any], slideId : Int) {
        slides[slideId].cityCardData.weeklySummaryInFav = weekJsonObj["summary"] as! String
        slides[slideId].cityCardData.weeklyIconInFav = weekJsonObj["icon"] as! String
        
        slides[slideId].cityCardData.weeklyWeatherDataInFav = weekJsonObj["data"] as! [[String:Any]]
        
        slides[slideId].cityCardData.arrayOfWeeklyCellDataInFav = []
        for i in 0 ... 7 {
            let currentCell = weeklyCellData(
                weatherIconStr: summaryIconMap[slides[slideId].cityCardData.weeklyWeatherDataInFav[i]["icon"] as! String] ?? "clear-day",
                dateStr: self.translateDate(timestamp: slides[slideId].cityCardData.weeklyWeatherDataInFav[i]["time"] as! TimeInterval),
                sunsetTimeStr: self.translatePST(timestamp: slides[slideId].cityCardData.weeklyWeatherDataInFav[i]["sunsetTime"] as! TimeInterval),
                sunriseTimeStr: self.translatePST(timestamp: slides[slideId].cityCardData.weeklyWeatherDataInFav[i]["sunriseTime"] as! TimeInterval)
            )
            slides[slideId].cityCardData.arrayOfWeeklyCellDataInFav.append(currentCell)
        }
        print("slides ", slideId , " is : ")
        print(slides[slideId].cityCardData.arrayOfWeeklyCellDataInFav)
        slides[slideId].weeklyTableView.reloadData()
        return
    }
    
    func setupCurrentWeather(currentJsonObj: [String:Any]?, slideId: Int) -> Void{
    //        print(currentJsonObj!)
            
        slides[slideId].cityCardData.tempStr = String(format:"%.0f", currentJsonObj?["temperature"] as! Double) + "°F"
        slides[slideId].cityCardData.weatherSummary = currentJsonObj?["summary"] as! String
        slides[slideId].cityCardData.weatherIconStr = currentJsonObj?["icon"] as! String
        slides[slideId].cityCardData.humidity = String(format: "%.1f", round(currentJsonObj?["humidity"] as! Double * 1000 / 10)) + " %"
        slides[slideId].cityCardData.windSpeed = String(format: "%.2f", currentJsonObj?["windSpeed"] as! Double) + " mph"
        slides[slideId].cityCardData.visibility = String(currentJsonObj?["visibility"] as! Double) + " km"
        slides[slideId].cityCardData.pressure = String(currentJsonObj?["pressure"] as! Double) + " mb"
        slides[slideId].cityCardData.currentWeatherInFav = currentJsonObj ?? [:]
            
        slides[slideId].tempLabel.text = slides[slideId].cityCardData.tempStr
        slides[slideId].summaryLabel.text = slides[slideId].cityCardData.weatherSummary
        slides[slideId].humidityLabel.text = slides[slideId].cityCardData.humidity
        slides[slideId].windSpeedLabel.text = slides[slideId].cityCardData.windSpeed
        slides[slideId].visibilityLabel.text = slides[slideId].cityCardData.visibility
        slides[slideId].pressureLabel.text = slides[slideId].cityCardData.pressure
        slides[slideId].weatherIcon.image = UIImage(named: summaryIconMap[slides[slideId].cityCardData.weatherIconStr] ?? "weather-sunny")
        return
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        print("current slides count: ", slides.count)
        
        // reset delegate and register for each appear
        slides[0].weeklyTableView.register(UINib(nibName: "WeeklyTableViewCell", bundle: nil), forCellReuseIdentifier: "WeeklyCellFromNib")
        slides[0].weeklyTableView.dataSource = self
        slides[0].weeklyTableView.delegate = self
        for i in 1 ..< slides.count {
            slides[i].weeklyTableView.register(UINib(nibName: "WeeklyTableViewCell", bundle: nil), forCellReuseIdentifier: "WeeklyCellFromNib-" + String(i))
            slides[i].weeklyTableView.dataSource = self
            slides[i].weeklyTableView.delegate = self
            let tapOnCard = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            slides[i].weatherCardView.addGestureRecognizer(tapOnCard)
            slides[i].weeklyTableView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
            slides[i].weeklyTableView.layer.cornerRadius = 5
            slides[i].weeklyTableView.layer.borderWidth = 1
            slides[i].weeklyTableView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        
        pageControl.numberOfPages = slides.count // view might appear due to back from detail

        view.bringSubviewToFront(pageControl)
        
        print("ViewWillAppear Called")
        // restore delegation lost in view transfer process
        // and request for weather data
        for i in 1 ..< slides.count {
            print("Init Slide no: " , i)
            // restore delegate to enable updateFav function
            slides[i].favListDelegate = self
            // update data for all fav citites weather card
            let geoURL = "http://webhw9-12345.appspot.com/latlng"
            Alamofire.request(geoURL,
                          method: .get,
                          parameters: ["address": slides[i].cityFullName])
            .validate()
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("Error while fetching geo for fav: ",(String(describing: response.result.error)))
                    return
                }

                guard let value = response.result.value as? [String: Any] else {
                    print("Malformed data received from geo service for fav")
                    return
                }

                slides[i].lat = String(value["lat"] as! Double)
                slides[i].lng = String(value["lng"] as! Double)
                let weatherURL = "http://webhw9-12345.appspot.com/weather/currently"
                Alamofire.request(weatherURL,
                                  method: .get,
                                  parameters: ["lat": slides[i].lat,
                                               "lng": slides[i].lng])
                .validate()
                .responseJSON { response in
                    guard response.result.isSuccess else {
                        print("Error while fetching weather for fav: (String(describing: response.result.error)")
                        return
                    }

                    guard let value = response.result.value as? [String: Any] else {
                        print("Malformed data received from getCurrentlyWeekly service for fav")
                        return
                    }

                    slides[i].cityCardData.currentWeatherInFav = value["currently"] as? [String: Any] ?? [:]
                    let tmpWeeklyWeatherInfo = value["daily"] as? [String: Any] ?? [:]
                    let tmpCurrentWeatherInfo = value["currently"] as? [String: Any] ?? [:]
                    self.setupCurrentWeather(currentJsonObj: tmpCurrentWeatherInfo, slideId: i)
                    self.storeWeeklyWeatherForFavCities(weekJsonObj: tmpWeeklyWeatherInfo, slideId: i)
                    slides[i].cityCardData.cityName = String(slides[i].cityFullName.split(separator: ",").first!)
                    
                    // update scrollview here, so data will be shown after get
                    if i + 1 >= slides.count {
                        // only call setup when slides data are populated, especially arrayOfWeeklyCellDataInFav
                        self.setupSlideScrollView(slides: slides)
                    }
                    
                }
                                        
            }
            
            
            // end of update for all fav cities
        }
        
        
        
        

//        // refresh data for table view
//        for eachView in slides {
//            eachView.weeklyTableView.reloadData()
//        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        SwiftSpinner.show("Loading...")

        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton


        weatherPageScrollView.delegate = self

        slides = createSlides()
        setupSlideScrollView(slides: slides)

        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        view.bringSubviewToFront(pageControl)




        // autocomplete
        autoCompleteTableView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        autoCompleteTableView.layer.cornerRadius = 5
        autoCompleteTableView.layer.borderWidth = 1
        autoCompleteTableView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        searchBar.delegate = self
        autoCompleteTableView.dataSource = self
        autoCompleteTableView.delegate = self
        autoCompleteTableView.register(UINib(nibName: "CityTableViewCell", bundle: nil), forCellReuseIdentifier: "CityCellFromNib")
        autoCompleteTableView.isHidden = true

        // location get
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestLocation()


    }
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        print("handleTap")
        if pageControl.currentPage == 0 {
            self.currentCityStr = self.slide0CityStr
            self.currentWeeklyData = self.slide0weeklyData
            self.currentWeeklyIcon = self.slide0weeklyIcon
            self.currentWeeklySummary = self.slide0weeklySummary
            self.currentWeatherIcon = self.slide0WeatherIcon
            self.currentWeatherSummary = self.slide0WeatherSummary
            self.currentWeather = self.slide0Weather
        } else {
            self.currentCityStr = slides[pageControl.currentPage].cityCardData.cityName
            self.currentWeeklyData = slides[pageControl.currentPage].cityCardData.weeklyWeatherDataInFav
            self.currentWeeklyIcon = slides[pageControl.currentPage].cityCardData.weeklyIconInFav
            self.currentWeeklySummary = slides[pageControl.currentPage].cityCardData.weeklySummaryInFav
            self.currentWeatherIcon = slides[pageControl.currentPage].cityCardData.weatherIconStr
            self.currentWeatherSummary = slides[pageControl.currentPage].cityCardData.weatherSummary
            self.currentWeather = slides[pageControl.currentPage].cityCardData.currentWeatherInFav
        }
        performSegue(withIdentifier: "showTabFromDefault", sender: self)
    }
    
    // START related to slides
    func createSlides() -> [Slide] {
        let slide1:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        
        // segue detect for detail tabs
        let tapOnCard0 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        slide1.weatherCardView.addGestureRecognizer(tapOnCard0)
        slide1.weeklyTableView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        slide1.weeklyTableView.layer.cornerRadius = 5
        slide1.weeklyTableView.layer.borderWidth = 1
        slide1.weeklyTableView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        var favSlides : [Slide] = []
        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
        if favList == nil {
            favList = []
        }
        // creat fav places for first time
        for i in 0 ..< favList!.count {
            let curSlide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
            curSlide.locationLabel.text = String(favList![i].split(separator: ",").first!)
            curSlide.cityFullName = favList![i]
            curSlide.ifFaved = true
            curSlide.favListDelegate = self // delegate for update function
            let tapOnCard = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            curSlide.weatherCardView.addGestureRecognizer(tapOnCard)
            curSlide.weeklyTableView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
            curSlide.weeklyTableView.layer.cornerRadius = 5
            curSlide.weeklyTableView.layer.borderWidth = 1
            curSlide.weeklyTableView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            favSlides.append(curSlide)
        }
        return [slide1] + favSlides
    }
    
    func setupSlideScrollView(slides : [Slide]) {
//        print("Set up slideScrollView called")
        weatherPageScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        weatherPageScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
        weatherPageScrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            if i == 0 {
                slides[i].favButtonOutlet.isHidden = true
            } else {
                slides[i].ifFaved = true
            }
            
            weatherPageScrollView.addSubview(slides[i])
        }
        
//        weatherPageScrollView.reloadInputViews()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == weatherPageScrollView {
            let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
            pageControl.currentPage = Int(pageIndex)
            // MARK : current values update to pass to tab bar view
        }
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
        
        self.slide0TempStr = String(format:"%.0f", currentJsonObj?["temperature"] as! Double) + "°F"
        self.slide0WeatherSummary = currentJsonObj?["summary"] as! String
        self.slide0WeatherIcon = currentJsonObj?["icon"] as! String
        self.slide0Humidity = String(format: "%.1f", round(currentJsonObj?["humidity"] as! Double * 1000 / 10)) + " %"
        self.slide0WindSpeed = String(format: "%.2f", currentJsonObj?["windSpeed"] as! Double) + " mph"
        self.slide0Visibility = String(currentJsonObj?["visibility"] as! Double) + " km"
        self.slide0Pressure = String(currentJsonObj?["pressure"] as! Double) + " mb"
        self.slide0Weather = currentJsonObj ?? [:]
            
        slides[0].tempLabel.text = self.slide0TempStr
        slides[0].summaryLabel.text = self.slide0WeatherSummary
        slides[0].humidityLabel.text = self.slide0Humidity
        slides[0].windSpeedLabel.text = self.slide0WindSpeed
        slides[0].visibilityLabel.text = self.slide0Visibility
        slides[0].pressureLabel.text = self.slide0Pressure
        slides[0].weatherIcon.image = UIImage(named: summaryIconMap[self.slide0WeatherIcon] ?? "weather-sunny")
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
        
        self.slide0weeklySummary = weekJsonObj?["summary"] as! String
        self.slide0weeklyIcon = weekJsonObj?["icon"] as! String
        
        self.slide0weeklyData = weekJsonObj?["data"] as! [[String:Any]]
        
        curLocArrayOfWeeklyCellData = []
        for i in 0 ... 7 {
            let currentCell = weeklyCellData(
                weatherIconStr: summaryIconMap[self.slide0weeklyData[i]["icon"] as! String] ?? "clear-day",
                dateStr: self.translateDate(timestamp: self.slide0weeklyData[i]["time"] as! TimeInterval),
                sunsetTimeStr: self.translatePST(timestamp: self.slide0weeklyData[i]["sunsetTime"] as! TimeInterval),
                sunriseTimeStr: self.translatePST(timestamp: self.slide0weeklyData[i]["sunriseTime"] as! TimeInterval)
            )
            curLocArrayOfWeeklyCellData.append(currentCell)
        }
        
        print("arrayOfWeeklyCellData count: ", curLocArrayOfWeeklyCellData.count)
        slides[0].weeklyTableView.reloadData()
        SwiftSpinner.hide()
        
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
                    self.slide0CityStr = firstLocation?.locality ?? "No Location"
                    slides[0].locationLabel.text = self.slide0CityStr
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
    // Table View Override
    // ****************
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == autoCompleteTableView {
            print("city table: " + String(cityList.count))
            return cityList.count
        } else {
            print("week table: " + String(curLocArrayOfWeeklyCellData.count))
            return curLocArrayOfWeeklyCellData.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == autoCompleteTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CityCellFromNib", for: indexPath) as! CityTableViewCell
            cell.cityLabel.text = cityList[indexPath.row]
            return cell
        } else if tableView == slides[0].weeklyTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCellFromNib", for: indexPath) as! WeeklyTableViewCell
            cell.weatherImgView.image = UIImage(named: curLocArrayOfWeeklyCellData[indexPath.row].weatherIconStr)
            cell.dateLabel.text = curLocArrayOfWeeklyCellData[indexPath.row].dateStr
            cell.sunriseTimeLabel.text = curLocArrayOfWeeklyCellData[indexPath.row].sunriseTimeStr
            cell.sunsetTimeLabel.text = curLocArrayOfWeeklyCellData[indexPath.row].sunsetTimeStr
            return cell
        }
        // MARK: to figure how to do it
        for i in 1 ..< slides.count {
            if tableView == slides[i].weeklyTableView {
                let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCellFromNib-" + String(i), for: indexPath) as! WeeklyTableViewCell
                let tempWeeklyCellData = slides[i].cityCardData.arrayOfWeeklyCellDataInFav
                cell.weatherImgView.image = UIImage(named: tempWeeklyCellData[indexPath.row].weatherIconStr)
                cell.dateLabel.text = tempWeeklyCellData[indexPath.row].dateStr
                cell.sunriseTimeLabel.text = tempWeeklyCellData[indexPath.row].sunriseTimeStr
                cell.sunsetTimeLabel.text = tempWeeklyCellData[indexPath.row].sunsetTimeStr
                return cell
            }
        }
        // this is a dumy return and should never happen
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCellFromNib", for: indexPath) as! CityTableViewCell
        cell.cityLabel.text = "Should not happen"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == autoCompleteTableView {
            // deselect and then segue to detail controller
            self.selectedCityStr = self.cityList[indexPath.row]
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.isHidden = true
            performSegue(withIdentifier: "showSearchDetail", sender: self)
        } else {
            // deselect other table view cell
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    
    
    // END of table view override
    
    // ****************
    // Search Bar Update
    // ****************
    
    func handleAutoComplete(listOfReturnCities: [String]){
        cityList = listOfReturnCities
//        for each in listOfReturnCities {
//            cityList.append(each.value as! String)
//        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search input: " + searchText)
        let url = "http://webhw9-12345.appspot.com/autocomplete"
        Alamofire.request(url,
                  method: .get,
                  parameters: ["currentString": searchText])
        .validate()
        .responseJSON { response in
            guard response.result.isSuccess else {
                print("Error while fetching autocomplete: (String(describing: response.result.error)")
                return
            }

            guard let value = response.result.value as? [String] else {
                print("Malformed data received from autocomplete service")
                return
            }
            
            self.handleAutoComplete(listOfReturnCities: value)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DetailViewController {
            let vc = segue.destination as? DetailViewController
            vc?.cityString = self.selectedCityStr
        } else if segue.destination is TabBarViewController {
            let vc = segue.destination as? TabBarViewController
            vc?.cityName = self.currentCityStr
            vc?.weeklyData = self.currentWeeklyData
            vc?.weeklyIcon = self.currentWeeklyIcon
            vc?.weeklySummary = self.currentWeeklySummary
            vc?.weatherIconStr = summaryIconMap[self.currentWeatherIcon]!
            vc?.weatherSummary = self.currentWeatherSummary
            vc?.windSpeed = String(round(self.currentWeather["windSpeed"] as! Double * 100) / 100) + " mph"
            vc?.pressure = String(round(self.currentWeather["pressure"] as! Double * 100) / 100) + " mb"
            vc?.precipitation = String(round(self.currentWeather["precipIntensity"] as! Double * 100) / 100) + " mmph"
            vc?.temperature = String(format:"%.0f",round(self.slide0Weather["temperature"] as! Double )) + "°F"
            vc?.humidity = String(round(self.currentWeather["humidity"] as! Double * 100) / 100) + " %"
            vc?.visibility = String(round(self.currentWeather["visibility"] as! Double * 100) / 100) + " km"
            vc?.cloudCover = String(round(self.currentWeather["cloudCover"] as! Double * 100) / 100) + " %"
            vc?.ozone = String(round(self.currentWeather["ozone"] as! Double * 100) / 100) + " DU"
        }
    }
    

    

}


// ******************
// Data Model for URL Request
// ******************

class WeatherRequest{
    let baseURL = "http://webhw9-12345.appspot.com/weather/"
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
                print("Error while fetching weather: (String(describing: response.result.error)")
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
