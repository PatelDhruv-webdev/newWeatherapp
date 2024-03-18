//
//  ViewController.swift
//  newWeatherapp
//
//  Created by Dhruv Patel on 14/03/24.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate , CLLocationManagerDelegate {
    
    @IBOutlet weak var searchField: UITextField!
    
    @IBOutlet weak var temp: UILabel!
    
    @IBOutlet weak var location: UILabel!
    
    @IBOutlet weak var weatherImg: UIImageView!
    @IBOutlet weak var toggleSwtich: UISwitch!
    
    let locationManager = CLLocationManager()
    var  isCelsius : Bool = true
    var currentWeather: WeatherResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        searchField.delegate = self
        displayColor()
        toggleSwtich.addTarget(self, action: #selector(toggleButton(_:)), for: .valueChanged)
    }
    
    
    private func displayColor() {
        let info = UIImage.SymbolConfiguration(paletteColors: [
            .systemRed, .systemBlue
        ])
        
        weatherImg.preferredSymbolConfiguration = info
        weatherImg.image = UIImage(systemName: "sun.haze")
    }
    
    
    @IBAction func locationButton(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @IBAction func searchButton(_ sender: UIButton) {
        searchField.endEditing(true)
        weatherDetail(search : searchField.text )
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text != "" {
            searchField.placeholder = "City Name "
            return true
        } else
        {
            searchField.placeholder = "Enter the city name "
            return false
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchField.endEditing(true)
        weatherDetail(search : searchField.text )
        
        return true
    }
    
    private func weatherDetail(search : String? ){
        guard let search = search else {
            
            return
        }
        
        guard let url = getURL(query : search) else {
            print("url does not found ")
            return
        }
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { data, response, error  in
         
            
            guard error == nil else {
                print ("Received error")
                return
            }
            guard let data = data else {
                print("No data found" )
                return
            }
            
            
            if let weatherResponse = self.parseData(data: data) {
                           self.currentWeather = weatherResponse // Store the current weather data
                           DispatchQueue.main.async {
                               self.location.text = weatherResponse.location.name
                               self.updateTemperatureDisplay() // Update the temperature display
                               self.updateWeatherConditionImage(weatherCode: weatherResponse.current.condition.code)
                           }
            }
        }
        dataTask.resume()
        
        
    }
    
    private func getURL(query: String) -> URL? {
        let baseurl = "https://api.weatherapi.com/v1/"
        let endPoint = "current.json"
        let apikey = "e6632e785a7548a2938142017241403"
        let urlString = "\(baseurl)\(endPoint)?key=\(apikey)&q=\(query)"
        
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: encodedString)
    }
    
    
    private func parseData(data : Data) -> WeatherResponse? {
        let decoder = JSONDecoder();
        
        var weather: WeatherResponse?
        
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("error")
        }
        
        return weather
    }
    

    private func updateWeatherConditionImage(weatherCode: Int) {
        let (weatherSymbol, color) = getWeatherSymbol(for: weatherCode)
        weatherImg.image = UIImage(systemName: weatherSymbol)
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .medium)
        weatherImg.preferredSymbolConfiguration = config
        weatherImg.tintColor = color
    }

    private func getWeatherSymbol(for weatherCode: Int) -> (String, UIColor) {
        switch weatherCode {
        case 1000, 113:
            return ("sun.max.fill", UIColor .systemRed)
        case 1063, 176, 1066, 179, 1219, 1087, 200, 1009, 1183, 296, 1003, 1186, 299, 1189, 302, 1243, 356, 1246, 359, 1273, 386, 1276, 389:
            return ("cloud.drizzle.fill", .systemRed)
        case 1114, 1117, 227, 230:
            return ("wind", .systemRed)
        default:
            return ("sun.max.trianglebadge.exclamationmark", .systemRed)
        }
    }

    
    
    
    struct WeatherResponse : Decodable {
        let location: Location
        let current: Weather
    }
    
    struct Location : Decodable {
        let name: String
    }
    
    struct Weather : Decodable {
        let temp_c: Float
        let temp_f: Float
        let condition: WeatherCondition
    }
    struct WeatherCondition : Decodable {
        let text: String
        let code: Int
    }
    
    @IBAction func toggleButton(_ sender: UISwitch) {
        isCelsius = sender.isOn
        updateTemperatureDisplay()
    }
    
    
     private func updateTemperatureDisplay() {
         guard let weather = currentWeather else { return }
         let temperature = isCelsius ? weather.current.temp_c : weather.current.temp_f
         let unit =  isCelsius ? "°C" : "°F"
         temp.text = "\(temperature)\(unit)"
     }
     
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.last {
                let lon = location.coordinate.longitude
                let lat = location.coordinate.latitude
                print("\(lat),\(lon)")
                let searchQuery = "\(lat),\(lon)"
                weatherDetail(search: searchQuery)
            }
        }
        
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)
    }
    
}
