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

var mapOfFavCitiesNames : [String:Int] = [:]
var slides:[Slide] = []

class SearchBarViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, favListDelegate {
    
    struct weeklyCellData {
        var weatherIconStr:String
        var dateStr:String
        var sunsetTimeStr:String
        var sunriseTimeStr:String
    }

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var weatherPageScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var autoCompleteTableView: UITableView!
    
    var locastionList = ["a", "b"]
    var currentWeatherControllerIndex = 0
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
    var currentWeather : [String:Any] = [:]
    
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

//    // Fav Related not working
//    func updateFav() {
//
//        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
//        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
//        if favList == nil {
//            favList = []
//        }
//        // check cities in slides are needed, delete not needed
//        for (name, inde) in mapOfFavCitiesNames {
//            // remove deleted city in slides
//            print(name)
//            print(inde)
//            print(slides[inde].ifFaved)
//            print(slides[inde].cityFullName)
//            if (favList?.contains(name))! == false && slides[inde].ifFaved == true {
//                print("remove slide at ", inde)
//                // first remove current subview from scrollview
//                slides[inde].removeFromSuperview()
//                // then remove from slides[]
//                slides.remove(at: inde)
//                // remove from map, which maintains all current fav cities to slides index
//                mapOfFavCitiesNames.removeValue(forKey: name)
//                // update all index after current subview
//                for (checkName, checkInde) in mapOfFavCitiesNames{
//                    if checkInde > inde {
//                        mapOfFavCitiesNames[checkName] = checkInde - 1
//                    }
//                }
//                // update page control
//                pageControl.numberOfPages = slides.count
//                pageControl.currentPage = inde - 1 // MARK: not working
//                // set focused subview to previous one
//                weatherPageScrollView.setContentOffset(CGPoint(x: inde * 414, y: 0), animated: true)
//            }
//            favList = favList?.filter { $0 != name}
//            print("updated current cached favlist: ", favList)
//        }
//        var curIndex = slides.count
//        for eachFullName in favList! {
//            // add new city to slides
//            let curSlide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
//            curSlide.locationLabel.text = String(eachFullName.split(separator: ",").first!)
//            // MARK: update fav slide input here
//            slides.append(curSlide)
//            mapOfFavCitiesNames[eachFullName] = curIndex
//            curIndex += 1
//            pageControl.numberOfPages = slides.count
//            print("current slides num, from updatefav: ", slides.count)
//        }
//        view.bringSubviewToFront(pageControl)
//        setupSlideScrollView(slides: slides)
//    }
    
    func updateFav() {

        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
        if favList == nil {
            favList = []
        }
        print("updated favlist: ", favList)
        // check cities in slides are needed, delete not needed
        var itIndex = 1
        while itIndex < slides.count {
            if (favList?.contains(slides[itIndex].cityFullName))! == false && slides[itIndex].ifFaved == true {
                print("remove slide at ", itIndex)
                // first remove current subview from scrollview
                slides[itIndex].removeFromSuperview()
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
//        var curIndex = slides.count
//        for eachFullName in favList! {
//            // add new city to slides
//            let curSlide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
//            curSlide.locationLabel.text = String(eachFullName.split(separator: ",").first!)
//            // MARK: update fav slide input here
//            slides.append(curSlide)
//            mapOfFavCitiesNames[eachFullName] = curIndex
//            curIndex += 1
//            pageControl.numberOfPages = slides.count
//            print("current slides num, from updatefav: ", slides.count)
//        }
        view.bringSubviewToFront(pageControl)
        setupSlideScrollView(slides: slides)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        print("current slides count: ", slides.count)
        setupSlideScrollView(slides: slides)
        pageControl.numberOfPages = slides.count // view might appear due to back from detail

        view.bringSubviewToFront(pageControl)
        
        // restore delegation lost in view transfer process
        for i in 1 ..< slides.count {
            slides[i].favListDelegate = self
        }


        // location get
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestLocation()

        // refresh data for table view
        slides[0].weeklyTableView.reloadData()
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


//        for i in 0..<arrayOfWeeklyCellData.count {
//            slides[i].weeklyTableView.dataSource = self
//            slides[i].weeklyTableView.delegate = self
//        }

        slides[0].weeklyTableView.register(UINib(nibName: "WeeklyTableViewCell", bundle: nil), forCellReuseIdentifier: "WeeklyCellFromNib")
        slides[0].weeklyTableView.dataSource = self
        slides[0].weeklyTableView.delegate = self

        // autocomplete
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

        // refresh data for table view
        slides[0].weeklyTableView.reloadData()

    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        print("handleTap")
        performSegue(withIdentifier: "showTabFromDefault", sender: self)
    }
    
    // START related to slides
    func createSlides() -> [Slide] {

        let slide1:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        
        // segue detect for detail tabs
        let tapOnCard = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        slide1.weatherCardView.addGestureRecognizer(tapOnCard)
        
        var favSlides : [Slide] = []
        let favListStr = UserDefaults.standard.string(forKey: "favList") ?? ""
        var favList = try? JSONDecoder().decode([String].self, from: favListStr.data(using: .utf8)!)
        if favList == nil {
            favList = []
        }
        for i in 0 ..< favList!.count {
            let curSlide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
            curSlide.locationLabel.text = String(favList![i].split(separator: ",").first!)
            curSlide.cityFullName = favList![i]
            curSlide.ifFaved = true
            print("creat slides iffaved: ", curSlide.ifFaved)
            curSlide.favListDelegate = self // delegate for update function
            // MARK: update fav slide input here
            mapOfFavCitiesNames[curSlide.cityFullName] = i + 1
            favSlides.append(curSlide)
        }
        
        
        
        return [slide1] + favSlides
    }
    
    func setupSlideScrollView(slides : [Slide]) {
        print("Set up slideScrollView called")
        
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
        self.currentWeather = currentJsonObj ?? [:]
            
        slides[0].tempLabel.text = self.currentTempStr
        slides[0].summaryLabel.text = self.currentSummary
        slides[0].humidityLabel.text = self.currentHumidity
        slides[0].windSpeedLabel.text = self.currentWindSpeed
        slides[0].visibilityLabel.text = self.currentVisibility
        slides[0].pressureLabel.text = self.currentPressure
        slides[0].weatherIcon.image = UIImage(named: self.summaryIconMap[self.currentIcon] ?? "weather-sunny")
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
        
        arrayOfWeeklyCellData = []
        for i in 0 ... 7 {
            let currentCell = weeklyCellData(
                weatherIconStr: self.summaryIconMap[self.weeklyData[i]["icon"] as! String] ?? "clear-day",
                dateStr: self.translateDate(timestamp: self.weeklyData[i]["time"] as! TimeInterval),
                sunsetTimeStr: self.translatePST(timestamp: self.weeklyData[i]["sunsetTime"] as! TimeInterval),
                sunriseTimeStr: self.translatePST(timestamp: self.weeklyData[i]["sunriseTime"] as! TimeInterval)
            )
            arrayOfWeeklyCellData.append(currentCell)
        }
        
        print("arrayOfWeeklyCellData count: ", arrayOfWeeklyCellData.count)
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
                    self.currentCityStr = firstLocation?.locality ?? "No Location"
                    slides[0].locationLabel.text = self.currentCityStr
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
            print("city table: " + String(arrayOfWeeklyCellData.count))
            return cityList.count
        } else {
            print("week table: " + String(arrayOfWeeklyCellData.count))
            return arrayOfWeeklyCellData.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == autoCompleteTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CityCellFromNib", for: indexPath) as! CityTableViewCell
            cell.cityLabel.text = cityList[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCellFromNib", for: indexPath) as! WeeklyTableViewCell
            cell.weatherImgView.image = UIImage(named: arrayOfWeeklyCellData[indexPath.row].weatherIconStr)
            cell.dateLabel.text = arrayOfWeeklyCellData[indexPath.row].dateStr
            cell.sunriseTimeLabel.text = arrayOfWeeklyCellData[indexPath.row].sunriseTimeStr
            cell.sunsetTimeLabel.text = arrayOfWeeklyCellData[indexPath.row].sunsetTimeStr
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == autoCompleteTableView {
            self.selectedCityStr = self.cityList[indexPath.row]
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.isHidden = true
            performSegue(withIdentifier: "showSearchDetail", sender: self)
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
            vc?.weeklyData = self.weeklyData
            vc?.weeklyIcon = self.weeklyIcon
            vc?.weeklySummary = self.weeklySummary
            vc?.weatherIconStr = self.summaryIconMap[self.currentIcon]!
            vc?.weatherSummary = self.currentSummary
            vc?.windSpeed = String(round(self.currentWeather["windSpeed"] as! Double * 100) / 100) + " mph"
            vc?.pressure = String(round(self.currentWeather["pressure"] as! Double * 100) / 100) + " mb"
            vc?.precipitation = String(round(self.currentWeather["precipIntensity"] as! Double * 100) / 100) + " mmph"
            vc?.temperature = String(format:"%.0f",round(self.currentWeather["temperature"] as! Double )) + "°F"
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
