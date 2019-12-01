//
//  Slide.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/11/25.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit

class Slide: UIView {
    var ifFaved = true
    
    
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
        
    }
    @IBOutlet weak var favButtonOutlet: UIButton!
    
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        self.weatherCardView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        
        self.weatherCardView.layer.cornerRadius = 5;
        self.weatherCardView.layer.masksToBounds = true;
        self.weatherCardView.layer.borderWidth = 1;
        self.weatherCardView.layer.borderColor = CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.fourDataView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        if !ifFaved {
            favButtonOutlet.setImage(UIImage(named: "trash-can"), for: .normal)
        }
    }

}
