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

class SearchBarViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var weatherPageScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    var locastionList = ["a", "b"]
    var currentWeatherControllerIndex = 0
    var slides:[Slide] = []
    var currentCityStr = ""
    var currentTempStr = ""
    var currentSummary = ""
    
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
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestLocation()

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
        print(currentJsonObj?["summary"] ?? currentJsonObj!)
        
        self.currentTempStr = String(format:"%.0f", currentJsonObj?["temperature"] as! Double) + "°F"
        self.currentSummary = currentJsonObj?["summary"] as! String 
            
        self.slides[0].tempLabel.text = self.currentTempStr
        self.slides[0].summaryLabel.text = self.currentSummary
        
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
                    weatherClient.getCurrentlyWeekly(handleCurrently: self.currentWeatherCallback)
                    
                    
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
    
    func getCurrentlyWeekly(handleCurrently: @escaping ([String:Any]?) -> Void) {
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
        }
    }
    
}
