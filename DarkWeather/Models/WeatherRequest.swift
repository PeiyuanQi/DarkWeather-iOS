//
//  WeatherRequest.swift
//  DarkWeather
//
//  Created by 戚培源 on 2019/11/26.
//  Copyright © 2019 戚培源. All rights reserved.
//

import UIKit

class WeatherRequest{
    let baseURL = "http://localhost:3000/"
    
    var onDataUpdate: ((_ data: String) -> Void)?

    
    init() {
        
    }
    
    func getCurrentlyWeekly(lat:String, lng: String) -> AnyObject {
        <#function body#>
    }
    
    func dataRequest() {
        // the data was received and parsed to String
        let data = "Data from wherever"

        onDataUpdate?(data)
    }
}
