//
//  NearbyLocationsMapViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 22.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import MapKit

private let kMapAnnotationIdentifier = "de.nearbyWeather.mkAnnotation"

class WeatherLocationMapAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    init(weatherDTO: OWMWeatherDTO) {
        let weatherConditionIdentifier = weatherDTO.weatherCondition.first?.identifier
        let weatherConditionSymbol = weatherConditionIdentifier != nil ? ConversionService.weatherConditionSymbol(fromWeathercode: weatherConditionIdentifier!) : nil
        let temperatureDescriptor = ConversionService.temperatureDescriptor(forTemperatureUnit: WeatherDataService.shared.temperatureUnit, fromRawTemperature: weatherDTO.atmosphericInformation.temperatureKelvin)
        let lat = weatherDTO.coordinates.latitude
        let lon = weatherDTO.coordinates.longitude
        
        title = weatherDTO.cityName
        subtitle = weatherConditionSymbol != nil ? "\(weatherConditionSymbol!) \(temperatureDescriptor)" : "\(temperatureDescriptor)"
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

class NearbyLocationsMapViewController: UIViewController {
    
    // MARK: - Assets
    
    /* Outlets */
    
    @IBOutlet weak var mapView: MKMapView!
    
    /* Properties */
    
    var weatherLocations: [CLLocation]!
    var weatherLocationMapAnnotations: [WeatherLocationMapAnnotation]!
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("NearbyLocationsMapVC_NavigationItemTitle", comment: "")
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        prepareMapAnnotations()
        prepareLocations()
        setMapRegion()
    }
    
    
    // MARK: - Private Helpers
    
    private func prepareMapAnnotations() {
        
        let singleLocationAnnotations = WeatherDataService.shared.singleLocationWeatherData?.flatMap {
            return WeatherLocationMapAnnotation(weatherDTO: $0)
        }
        let multiLocationAnnotations = WeatherDataService.shared.multiLocationWeatherData?.flatMap {
            return WeatherLocationMapAnnotation(weatherDTO: $0)
        }
        weatherLocationMapAnnotations = [WeatherLocationMapAnnotation]()
        weatherLocationMapAnnotations.append(contentsOf: singleLocationAnnotations ?? [WeatherLocationMapAnnotation]())
        weatherLocationMapAnnotations.append(contentsOf: multiLocationAnnotations ?? [WeatherLocationMapAnnotation]())
        
        mapView.addAnnotations(weatherLocationMapAnnotations)
    }
    
    private func prepareLocations() {
        let singleLocations = WeatherDataService.shared.singleLocationWeatherData?.flatMap {
            return CLLocation(latitude: $0.coordinates.longitude, longitude: $0.coordinates.latitude)
        }
        let multiLocations = WeatherDataService.shared.multiLocationWeatherData?.flatMap {
            return CLLocation(latitude: $0.coordinates.longitude, longitude: $0.coordinates.latitude)
        }
        weatherLocations = [CLLocation]()
        weatherLocations.append(contentsOf: singleLocations ?? [CLLocation]())
        weatherLocations.append(contentsOf: multiLocations ?? [CLLocation]())
    }
    
    private func setMapRegion() {
        if LocationService.shared.locationPermissionsGranted, let currentLocation = LocationService.shared.currentLocation {
            let region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 25000, 25000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func configure() {
        navigationController?.navigationBar.styleStandard(withTransluscency: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
    }
}

extension NearbyLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? WeatherLocationMapAnnotation else {
            return nil
        }
        
        if #available(iOS 11, *) {
            var viewForCurrentAnnotation: MKMarkerAnnotationView?
            if let dequeuedAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: kMapAnnotationIdentifier) as? MKMarkerAnnotationView {
                dequeuedAnnotation.annotation = annotation
                viewForCurrentAnnotation = dequeuedAnnotation
            } else {
                viewForCurrentAnnotation = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: kMapAnnotationIdentifier)
                viewForCurrentAnnotation?.canShowCallout = true
                viewForCurrentAnnotation?.calloutOffset = CGPoint(x: -5, y: 5)
            }
            return viewForCurrentAnnotation
        } else {
            var viewForCurrentAnnotation: MKAnnotationView?
            if let dequeuedAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: kMapAnnotationIdentifier) {
                dequeuedAnnotation.annotation = annotation
                viewForCurrentAnnotation = dequeuedAnnotation
            } else {
                viewForCurrentAnnotation = MKAnnotationView(annotation: annotation, reuseIdentifier: kMapAnnotationIdentifier)
                viewForCurrentAnnotation?.canShowCallout = true
                viewForCurrentAnnotation?.calloutOffset = CGPoint(x: -5, y: 5)
            }
            return viewForCurrentAnnotation
        }
    }
}
