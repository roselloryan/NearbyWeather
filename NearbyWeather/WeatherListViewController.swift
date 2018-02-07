//
//  WeatherListViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 20.10.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import SafariServices
import RainyRefreshControl

class WeatherListViewController: UIViewController {
    
    // MARK: - Properties
    
    private var refreshControl = RainyRefreshControl()
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonRowContainerView: UIView!
    @IBOutlet weak var buttonRowStackView: UIStackView!
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 105, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        
        tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(WeatherListViewController.configureOnDidAppBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WeatherListViewController.configureOnWeatherDataServiceDidUpdate), name: Notification.Name(rawValue: kWeatherServiceDidUpdate), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.value(forKey: kIsInitialLaunch) == nil {
            UserDefaults.standard.set(false, forKey: kIsInitialLaunch)
            updateWeatherData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl.endRefreshing()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Private Helpers
    
    private func configure() {
        navigationController?.navigationBar.styleStandard(withTransluscency: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        configureNavigationTitle()
        
        buttonRowContainerView.layer.cornerRadius = 10
        buttonRowContainerView.layer.backgroundColor = UIColor.nearbyWeatherStandard.cgColor
        buttonRowContainerView.addDropShadow(radius: 10)
        
        buttonRowContainerView.bringSubview(toFront: buttonRowStackView)
        
        refreshButton.tintColor = .white
        configureSortButton()
        infoButton.tintColor = .white
        settingsButton.tintColor = .white
        
        refreshControl.addTarget(self, action: #selector(WeatherListViewController.updateWeatherData), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    @objc private func configureOnDidAppBecomeActive() {
        configureSortButton()
    }
    @objc private func configureOnWeatherDataServiceDidUpdate() {
        configureNavigationTitle()
        tableView.reloadData()
    }
    
    private func configureNavigationTitle() {
        let title = "NearbyWeather"
        if let lastRefreshDate = UserDefaults.standard.object(forKey: kWeatherDataLastRefreshDateKey) as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: lastRefreshDate)
            let subtitle = String(format: NSLocalizedString("LocationsListTVC_LastRefresh", comment: ""), dateString)
            navigationItem.setTitle(title, andSubtitle: subtitle)
        } else {
            navigationItem.title = title
        }
    }
    
    private func configureSortButton() {
        let locationAvailable = LocationService.shared.locationPermissionsGranted
        sortButton.isEnabled = locationAvailable
        sortButton.tintColor = locationAvailable ? .white : .gray
    }
    
    @objc private func updateWeatherData() {
        refreshControl.beginRefreshing()
        WeatherDataManager.shared.update(withCompletionHandler: {
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        })
    }
    
    @objc private func reloadTableView(_ notification: Notification) {
        tableView.reloadData()
    }
    
    private func triggerSortAlert() {
        let sortAlert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("LocationsListTVC_SortAlert_Cancel", comment: ""), style: .cancel, handler: nil)
        let sortByNameAction = UIAlertAction(title: NSLocalizedString("LocationsListTVC_SortAlert_Action1", comment: ""), style: .default, handler: { paramAction in
            WeatherDataManager.shared.sortData(byOrientation: .name)
            self.tableView.reloadData()
        })
        let sortByTemperatureAction = UIAlertAction(title: NSLocalizedString("LocationsListTVC_SortAlert_Action2", comment: ""), style: .default, handler: { paramAction in
            WeatherDataManager.shared.sortData(byOrientation: .temperature)
            self.tableView.reloadData()
        })
        
        let sortByDistanceAction = UIAlertAction(title: NSLocalizedString("LocationsListTVC_SortAlert_Action3", comment: ""), style: .default, handler: { paramAction in
            WeatherDataManager.shared.sortData(byOrientation: .distance)
            self.tableView.reloadData()
        })
        
        sortAlert.addAction(cancelAction)
        sortAlert.addAction(sortByNameAction)
        sortAlert.addAction(sortByTemperatureAction)
        if LocationService.shared.locationPermissionsGranted { sortAlert.addAction(sortByDistanceAction) }
        present(sortAlert, animated: true, completion: nil)
    }
    
    
    // MARK: - Button Interaction
    
    @IBAction func didTapSettingsButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destinationViewController = storyboard.instantiateViewController(withIdentifier: "SettingsTVC") as! SettingsTableViewController
        let destinationNavigationController = UINavigationController(rootViewController: destinationViewController)
        destinationNavigationController.addVerticalCloseButton(withCompletionHandler: nil)
        navigationController?.present(destinationNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destinationViewController = storyboard.instantiateViewController(withIdentifier: "NearbyLocationsMapViewController") as! NearbyLocationsMapViewController
        let destinationNavigationController = UINavigationController(rootViewController: destinationViewController)
        destinationNavigationController.addVerticalCloseButton(withCompletionHandler: nil)
        navigationController?.present(destinationNavigationController, animated: true, completion: nil)
    }

    @IBAction func sortButtonPressed(_ sender: UIButton) {
        triggerSortAlert()
    }
    
    @IBAction func didTapRefreshButton(_ sender: UIButton) {
        updateWeatherData()
    }
    
    @IBAction func openWeatherMapButtonPressed(_ sender: UIButton) {
        guard let url = URL(string: "https://openweathermap.org") else {
            return
        }
        let safariController = SFSafariViewController(url: url)
        if #available(iOS 10, *) {
            safariController.preferredControlTintColor = .nearbyWeatherStandard
        } else {
            safariController.view.tintColor = .nearbyWeatherStandard
        }
        present(safariController, animated: true, completion: nil)
    }
}

extension WeatherListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
}

extension WeatherListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !WeatherDataManager.shared.hasSingleLocationWeatherData && !WeatherDataManager.shared.hasMultiLocationWeatherData {
                return nil
        }
        switch section {
        case 0:
            return NSLocalizedString("LocationsListTVC_TableViewSectionHeader1", comment: "")
        case 1:
            return NSLocalizedString("LocationsListTVC_TableViewSectionHeader2", comment: "")
        default:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if !WeatherDataManager.shared.hasSingleLocationWeatherData && !WeatherDataManager.shared.hasMultiLocationWeatherData {
            return 1
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !WeatherDataManager.shared.hasSingleLocationWeatherData && !WeatherDataManager.shared.hasMultiLocationWeatherData {
            return 1
        }
        switch section {
        case 0:
            return 1
        case 1:
            guard let multiLocationWeatherData = WeatherDataManager.shared.multiLocationWeatherData else {
                return 1
            }
            return multiLocationWeatherData.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !WeatherDataManager.shared.hasSingleLocationWeatherData && !WeatherDataManager.shared.hasMultiLocationWeatherData {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell

                cell.backgroundColor = .clear
                
                cell.warningImageView.tintColor = .white
                
                cell.noticeLabel.text = NSLocalizedString("LocationsListTVC_AlertNoData", comment: "")
                cell.backgroundColorView.layer.cornerRadius = 5.0
                cell.startAnimationTimer()
                return cell
        }
        
        var weatherData: LocationWeatherDataDTO?
        var alertNotice: String?
        
        if indexPath.section == 0 {
            if let data = WeatherDataManager.shared.singleLocationWeatherData?[indexPath.row] {
                weatherData = data
            } else {
                alertNotice = NSLocalizedString("LocationsListTVC_AlertIncorrectBookmarkedCity", comment: "")
            }
        }
        if indexPath.section == 1 {
            if let data = WeatherDataManager.shared.multiLocationWeatherData?[indexPath.row] {
                weatherData = data
            } else {
                alertNotice = NSLocalizedString("LocationsListTVC_AlertLocationUnavailable", comment: "")
            }
        }
        
        if let weatherDTO = weatherData {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherDataCell", for: indexPath) as! WeatherDataCell
            
            cell.weatherDataIdentifier = weatherDTO.cityID
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            cell.backgroundColorView.layer.cornerRadius = 5.0
            cell.backgroundColorView.layer.backgroundColor = UIColor.nearbyWeatherBubble.cgColor
            
            cell.cityNameLabel.textColor = .white
            cell.cityNameLabel.font = .preferredFont(forTextStyle: .headline)
            
            cell.temperatureLabel.textColor = .white
            cell.temperatureLabel.font = .preferredFont(forTextStyle: .subheadline)
            
            cell.cloudCoverageLabel.textColor = .white
            cell.cloudCoverageLabel.font = .preferredFont(forTextStyle: .subheadline)
            
            cell.humidityLabel.textColor = .white
            cell.humidityLabel.font = .preferredFont(forTextStyle: .subheadline)
            
            cell.windspeedLabel.textColor = .white
            cell.windspeedLabel.font = .preferredFont(forTextStyle: .subheadline)
            
            let weatherConditionSymbol = ConversionService.weatherConditionSymbol(fromWeathercode: weatherDTO.weatherCondition[0].identifier)
            cell.weatherConditionLabel.text = weatherConditionSymbol
            
            cell.cityNameLabel.text = weatherDTO.cityName
            
            let temperatureDescriptor = ConversionService.temperatureDescriptor(forTemperatureUnit: WeatherDataManager.shared.temperatureUnit, fromRawTemperature: weatherDTO.atmosphericInformation.temperatureKelvin)
            cell.temperatureLabel.text = "🌡 \(temperatureDescriptor)"
            
            cell.cloudCoverageLabel.text = "☁️ \(weatherDTO.cloudCoverage.coverage)%"
            
            cell.humidityLabel.text = "💧 \(weatherDTO.atmosphericInformation.humidity)%"
            
            let windspeedDescriptor = ConversionService.windspeedDescriptor(forDistanceSpeedUnit: WeatherDataManager.shared.windspeedUnit, forWindspeed: weatherDTO.windInformation.windspeed)
            cell.windspeedLabel.text = "🎏 \(windspeedDescriptor)"
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            cell.warningImageView.tintColor = .white
            
            cell.noticeLabel.text = alertNotice
            cell.backgroundColorView.layer.cornerRadius = 5.0
            cell.startAnimationTimer()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? WeatherDataCell,
            let weatherDataIdentifier = selectedCell.weatherDataIdentifier else {
                return
        }
        guard let weatherDTO = WeatherDataManager.shared.weatherDTO(forIdentifier: weatherDataIdentifier) else {
            return
        }

        let destinationViewController = WeatherDetailViewController.instantiateFromStoryBoard(withTitle: weatherDTO.cityName, weatherDTO: weatherDTO)
        navigationItem.removeTextFromBackBarButton()
        navigationController?.pushViewController(destinationViewController, animated: true)
    }
}