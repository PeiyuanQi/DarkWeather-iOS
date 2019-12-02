//
//  TodayViewController.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/12/1.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit

class TodayViewController: UIViewController {
    @IBOutlet weak var wsView: UIView!
    @IBOutlet weak var pressureView: UIView!
    @IBOutlet weak var precipitationView: UIView!
    @IBOutlet weak var tempView: UIView!
    @IBOutlet weak var summaryView: UIView!
    @IBOutlet weak var humidityView: UIView!
    @IBOutlet weak var visibilityView: UIView!
    @IBOutlet weak var cloudyView: UIView!
    @IBOutlet weak var ozView: UIView!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var presureLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var weatherIconView: UIImageView!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var visibilityLabel: UILabel!
    @IBOutlet weak var cloudyLabel: UILabel!
    @IBOutlet weak var ozLabel: UILabel!
    
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
        
        let listOfView = [wsView, pressureView, precipitationView, tempView, summaryView, humidityView, visibilityView, cloudyView, ozView]
        
        for eachView in listOfView {
            eachView?.backgroundColor =  UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
            eachView?.layer.cornerRadius = 3
            eachView?.layer.borderWidth = 1
            eachView?.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        weatherIconView.image = UIImage(named: self.weatherIconStr)
        summaryLabel.text = self.weatherSummary
        
        windSpeedLabel.text = self.windSpeed
        presureLabel.text = self.pressure
        precipitationLabel.text = self.precipitation
        temperatureLabel.text = self.temperature
        humidityLabel.text = self.humidity
        visibilityLabel.text = self.visibility
        cloudyLabel.text = self.cloudCover
        ozLabel.text = self.ozone
        
        

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
