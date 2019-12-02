//
//  WeeklyViewController.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/12/1.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit
import Charts

class WeeklyViewController: UIViewController {
    @IBOutlet weak var weeklyIconView: UIImageView!
    @IBOutlet weak var weeklySummaryLabel: UILabel!
    @IBOutlet weak var weeklyCardView: UIView!
    @IBOutlet weak var chartView: LineChartView!
    
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
    
    var minmaxWeeklyData: [[Double]] = []
    var weeklyIcon = "weather-sunny"
    var weeklySummary = "PlaceHolder"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        weeklyCardView.layer.cornerRadius = 5
        weeklyCardView.layer.masksToBounds = true
        weeklyCardView.layer.borderWidth = 1
        weeklyCardView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        weeklyCardView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        
        weeklyIconView.image = UIImage(named: self.summaryIconMap[self.weeklyIcon] ?? "weather-sunny")
        weeklySummaryLabel.text = self.weeklySummary
        
        chartView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        chartView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        chartView.layer.borderWidth = 1
        
        var minDataEntry = [ChartDataEntry]()
        var maxDataEntry = [ChartDataEntry]()
        for i in 0 ..< minmaxWeeklyData.count {
            let minT = ChartDataEntry(x: Double(i), y: minmaxWeeklyData[i][0])
            let maxT = ChartDataEntry(x: Double(i), y: minmaxWeeklyData[i][1])
            minDataEntry.append(minT)
            maxDataEntry.append(maxT)
        }
        let plotData = LineChartData()
        let lineMin = LineChartDataSet(entries: minDataEntry, label: "Minimum Temperature (°F)")
        lineMin.colors = [NSUIColor.white]
        lineMin.circleHoleColor = NSUIColor.white
        lineMin.circleColors = [NSUIColor.white]
        let lineMax = LineChartDataSet(entries: maxDataEntry, label: "Maximum Temperature (°F)")
        lineMax.colors = [NSUIColor.orange]
        lineMax.circleColors = [NSUIColor.orange]
        lineMax.circleHoleColor = NSUIColor.orange
        plotData.addDataSet(lineMin)
        plotData.addDataSet(lineMax)
        chartView.data = plotData
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
