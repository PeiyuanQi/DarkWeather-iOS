//
//  WeeklyTableViewCell.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/11/29.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit

class WeeklyTableViewCell: UITableViewCell {
    @IBOutlet weak var weatherImgView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sunriseTimeLabel: UILabel!
    @IBOutlet weak var sunsetTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
