//
//  ViewController.swift
//  LocationPicker
//
//  Created by 荆文征 on 2019/4/12.
//  Copyright © 2019 aimobier. All rights reserved.
//

import UIKit

import MapKit

import Pulley

public protocol LocationPickerViewControllerDelegate: class {
    
    /// user click cancel button
    func userDidCancel()
    /// user select a location
    func userSelectLocation(placemark: CLPlacemark)
}

/// 选择地理位置视图
/// info.plist 需要配置
///
/// NSLocationAlwaysAndWhenInUseUsageDescription 在应用运行期间访问地理位置信息
/// NSLocationWhenInUseUsageDescription 始终访问
public class LocationPickerViewController: PulleyViewController {
    
    /// map viewController
    private let mapViewController: MapViewController
    /// peek viewController
    private let peekViewController: PeekViewController
    
    /// LocationPickerViewControllerDelegate
    public weak var pickerDelegate: LocationPickerViewControllerDelegate? {
        didSet{
            mapViewController.pickerDelegate = pickerDelegate
            peekViewController.pickerDelegate = pickerDelegate
        }
    }
    
    public init() {
        
        let viewController = MapViewController()
        
        mapViewController = viewController
        peekViewController = PeekViewController(viewController.mapView)
        
        super.init(contentViewController: mapViewController, drawerViewController: peekViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
    }
}

class MapViewController: UIViewController, PulleyPrimaryContentControllerDelegate {
    
    let mapView = MKMapView()
    
    var pickerDelegate: LocationPickerViewControllerDelegate?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.pulleyViewController?.displayMode = .automatic
        
        mapView.showsScale = true
        
        self.view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
            view.addSubview(visualEffectView)
            visualEffectView.translatesAutoresizingMaskIntoConstraints = false
            visualEffectView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            visualEffectView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            visualEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            visualEffectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        }
        
        let locationController = MapViewLocationController(mapView)
        locationController.tag = 11
        self.view.addSubview(locationController)
        locationController.translatesAutoresizingMaskIntoConstraints = false
        locationController.widthAnchor.constraint(equalToConstant: 90).isActive = true
        locationController.heightAnchor.constraint(equalToConstant: 44).isActive = true
        if #available(iOS 11.0, *) {
            locationController.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -4).isActive = true
            locationController.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 18).isActive = true
        } else {
            locationController.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -4).isActive = true
            locationController.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 18).isActive = true
        }
        
        mapView.showsUserLocation = true
        
        locationCapture = LocationCapture(self, barItem: locationController.locationButton)
        
        locationController.closeButton.target = self
        locationController.closeButton.action = #selector(closeButtonClicked)
    }
    
    @objc private func closeButtonClicked(){
        
        self.pickerDelegate?.userDidCancel()
    }
    
    private var locationCapture: LocationCapture?
    
    private var topLayoutMarginsValue: CGFloat = 0
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        topLayoutMarginsValue = self.view.viewWithTag(11)!.frame.maxY + 8 - UIDevice.current.safeAreaInsets.top
    }
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        
        if drawer.currentDisplayMode == .panel {
            
            return mapView.layoutMargins = UIEdgeInsets(top: topLayoutMarginsValue, left: 0, bottom: 0, right: 0)
        }
        
        mapView.layoutMargins = UIEdgeInsets(top: topLayoutMarginsValue, left: 0, bottom: min(distance - bottomSafeArea, 264), right: 0)
    }
}

extension MapViewController{
    
    class LocationCapture: NSObject, CLLocationManagerDelegate {
        
        private let locationManager = CLLocationManager()
        
        private var barItem: UIBarButtonItem
        
        private weak var viewController: UIViewController?
        
        init(_ viewController: UIViewController, barItem: UIBarButtonItem){
            
            self.barItem = barItem
            
            self.viewController = viewController
            
            super.init()
            
            locationManager.delegate = self
            
            authorStatusDidChange(status: CLLocationManager.authorizationStatus())
        }
        
        func authorStatusDidChange(status: CLAuthorizationStatus) {
            
            /// 按钮 设置
            barItem.isEnabled = status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse
            
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined: notDeterminedHandleMethod() // 用户没有申请过 定位权限
            case .denied: deniedHandleMethod() // 拒绝申请
            case .restricted: restrictedHandleMethod() // 拒绝 申请过 定位权限
            case .authorizedAlways,.authorizedWhenInUse: authorizedHandleMethod() // 是否允许 定位权限
            @unknown default:
                print("Swift 5 错误")
            }
        }
        
        func authorizedHandleMethod() {
            
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = CLLocationDistance(100)
            locationManager.startUpdatingLocation()
        }
        
        func notDeterminedHandleMethod() {
            
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        }
        
        func deniedHandleMethod() {
            
            let alert = UIAlertController(title: nil, message: "没有定位权限授权，无法访问用户位置", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "好的", style: UIAlertAction.Style.cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "打开", style: UIAlertAction.Style.default, handler: { (_) in
                
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            }))
            
            viewController?.present(alert, animated: true, completion: nil)
        }
        
        func restrictedHandleMethod() {
            
            viewController?.showMessage("定位信息访问受限")
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            
            authorStatusDidChange(status: status)
        }
    }
}

extension MapViewController{
    
    class MapViewLocationController: UIView{
        
        let locationButton: MKUserTrackingBarButtonItem
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.stop, target: nil, action: nil)
        
        init(_ mapView: MKMapView) {
            
            locationButton = MKUserTrackingBarButtonItem(mapView: mapView)
            
            super.init(frame: CGRect.zero)
            
            // shadow
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOffset = CGSize(width: 3, height: 3)
            layer.shadowOpacity = 0.7
            layer.shadowRadius = 4.0
            
            /// 内容展示
            let toolBar = UIToolbar()
            toolBar.clipsToBounds = true
            
            closeButton.imageInsets = UIEdgeInsets(top: 0, left: 9.5, bottom: 0, right: 9.5)
            
            toolBar.setItems([locationButton,UIBarButtonItem(customView: UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))),closeButton], animated: false)
            
            let contextView = UIView()
            contextView.addSubview(toolBar)
            toolBar.translatesAutoresizingMaskIntoConstraints = false
            toolBar.topAnchor.constraint(equalTo: contextView.topAnchor).isActive = true
            toolBar.bottomAnchor.constraint(equalTo: contextView.bottomAnchor).isActive = true
            toolBar.centerYAnchor.constraint(equalTo: contextView.centerYAnchor).isActive = true
            toolBar.centerXAnchor.constraint(equalTo: contextView.centerXAnchor).isActive = true
            
            self.addSubview(contextView)
            contextView.layer.cornerRadius = 10
            contextView.clipsToBounds = true
            contextView.translatesAutoresizingMaskIntoConstraints = false
            contextView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            contextView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            contextView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            contextView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            
            let borderView  = UIView(frame: CGRect(x: 0, y: 10, width: 1, height: 24))
            borderView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
            addSubview(borderView)
            borderView.translatesAutoresizingMaskIntoConstraints = false
            borderView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            borderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            borderView.heightAnchor.constraint(equalToConstant: 24).isActive = true
            borderView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            
            super.layoutSubviews()
            
            //            self.layer.anchorPoint = CGPoint(x: 1, y: 1)
            
            //            self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        }
    }
}

class PeekViewController: UIViewController {

    var pickerDelegate: LocationPickerViewControllerDelegate?
    
    /// 地图视图
    private let mapView: MKMapView
    
    /// top layer
    private let gripperView = UIView()
    /// 约束
    private var gripperViewVConstarint: NSLayoutConstraint?
    
    /// 下方 border
    private let bottomBorderView = PeekBottomBorderView()
    private var bottomBorderHeightConstraint: NSLayoutConstraint?
    
    /// 表格
    let tableView = UITableView()
    
    let headerView = PeekHeaderView()
    
    /// 是否显示过 用户的 位置
    private var isShowUserLocation = false
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    init(_ mapView: MKMapView){
        
        self.mapView = mapView
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        headerView.searchBar.delegate = self
        headerView.searchBar.placeholder = "搜索地名或者地区"
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: PeekHeaderView.HEIGHT).isActive = true
        
        mapView.delegate = self
        let tapGestureRengnizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGetureRecognizer(tap:)))
        tapGestureRengnizer.delegate = self
        mapView.addGestureRecognizer(tapGestureRengnizer)
        
        /// self size
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.backgroundColor = UIColor.clear
        tableView.register(PeekTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        view.addSubview(bottomBorderView)
        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        bottomBorderView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomBorderView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomBorderView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomBorderHeightConstraint = bottomBorderView.heightAnchor.constraint(equalToConstant: 21)
        bottomBorderHeightConstraint?.isActive = true
        /// add table view bottom layout
        tableView.bottomAnchor.constraint(equalTo: bottomBorderView.topAnchor).isActive = true
        
        gripperView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        gripperView.layer.cornerRadius = 2.5
        self.view.addSubview(gripperView)
        gripperView.translatesAutoresizingMaskIntoConstraints = false
        gripperView.widthAnchor.constraint(equalToConstant: 36).isActive = true
        gripperView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        gripperView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        if #available(iOS 10.0, *){
            self.pulleyViewController?.feedbackGenerator = UISelectionFeedbackGenerator()
        }
    }
    
    /// 用户 位置信息 解析对象
    var userLocationGeocoder = CLGeocoder()
    
    var deadlineWorkItem: DispatchWorkItem?
    
    let annotation = PeekAnnotation()
    
    @objc func handleTapGetureRecognizer(tap: UITapGestureRecognizer){
        
        let coordinate = mapView.convert(tap.location(in: mapView), toCoordinateFrom: mapView)
        
        deadlineWorkItem = DispatchWorkItem { [weak self] in
            self?.deadlineMethod(coordinate)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3, execute: deadlineWorkItem!)
    }
    
    func deadlineMethod(_ coordinate: CLLocationCoordinate2D) {
        
        annotation.coordinate = coordinate
        annotation.title = "解析中"
        
        mapView.removeAnnotation(annotation)
        mapView.addAnnotation(annotation)
        
        // Look up the location and pass it to the completion handler
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude),completionHandler: {[weak self] (placemarks, error) in
            
            /// Geocoder error
            if let error = error as NSError? {
                
                self?.annotation.placemark = nil
                
                self?.annotation.title = CLError(_nsError: error).pickerdescription
                
            }else{
                
                self?.annotation.placemark = placemarks?.first
                
                self?.annotation.title = placemarks?.first?.formatStringNoBreakLine
            }
            
            if let annotation = self?.annotation {
                
                self?.mapView.selectAnnotation(annotation, animated: true)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: UIDevice.current.safeAreaInsets.bottom, right: 0.0)
    }
    
    /// 搜索 地址
    fileprivate func searchKeyWorld(_ keyWorld: String?){
        
        clearMethod()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyWorld
        
        MKLocalSearch(request: request).start { [weak self] (reponse, error) in
            
            guard let self = self else { return }
            
            if let error = error as NSError? {
                
                return self.showMessage(MKError(_nsError: error).pickerdescription)
            }
            
            self.handleSearchResults(reponse)
            
            self.result = SearchResult(reponse: reponse, error: error)
            self.tableView.reloadData()
        }
    }
    
    var result: SearchResult?
    
    struct SearchResult {
        
        /// 结果
        var reponse: MKLocalSearch.Response?
        /// 错误
        var error: Error?
    }
    
    func clearMethod(){
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        result = nil
        tableView.reloadData()
    }
    
    func handleSearchResults(_ reponse: MKLocalSearch.Response?){
        
        guard let reponse = reponse else { return }
        
        for item in reponse.mapItems {
            
            self.mapView.addAnnotation(item.placemark)
        }
        
        self.mapView.setRegion(reponse.boundingRegion, animated: true)
    }
}

extension PeekViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if let selectGesture = touch.view?.isKind(of: MKAnnotationView.self), selectGesture {
            
            return false
        }
        
        return true
    }
}

extension PeekViewController{
    
    class PeekPinAnnotationView: MKPinAnnotationView{

        private weak var delegate: PeekLocationSelectedDelegate?
        
        private let button = UIButton(type: UIButton.ButtonType.system)
        
        func configureAnnitation(_ annotation: MKAnnotation, delegate: PeekLocationSelectedDelegate?) {
            
            self.delegate = delegate
            
            if let annotation = annotation as? PeekAnnotation,annotation.placemark == nil {
                
                return self.rightCalloutAccessoryView = nil
            }
            
            self.rightCalloutAccessoryView = button
        }
        
        override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
            
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            self.canShowCallout = true
            
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
            
            button.addTarget(self, action: #selector(selectButtonClicked), for: UIControl.Event.touchUpInside)
            button.setAttributedTitle("选定".font(UIFont.boldSystemFont(ofSize: 14)), for: UIControl.State.normal)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func selectButtonClicked(){
            
            guard let annotation = self.annotation else{ return }
            
            if let placemark = annotation as? MKPlacemark {
                
                delegate?.locationDidSelected(placemark)
            }
            
            if let annotation = annotation as? PeekAnnotation,let placemark = annotation.placemark {
                
                delegate?.locationDidSelected(placemark)
            }
        }
    }
}

extension PeekViewController: MKMapViewDelegate{
    
    /// 新建一个 选中按钮 在 UserLocation 被惦记的时候 将该视图 增加到 MKAnnotationView rightCalloutAccessoryView 中
    ///
    /// - Parameter placemark: 位置信息
    /// - Returns: 按钮度喜庆
    private func createSelectButton(_ placemark: CLPlacemark) -> UIButton {
        
        let button = UIButton(type: UIButton.ButtonType.system)
        
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        
        button.setAttributedTitle("选定".font(UIFont.boldSystemFont(ofSize: 14)), for: UIControl.State.normal)
        
        button.addAction(for: UIControl.Event.touchUpInside) { [weak self] in
            
            self?.locationDidSelected(placemark)
        }
        
        return button
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        deadlineWorkItem?.cancel()
        
        if let annotationView = view as? PeekPinAnnotationView, let annotation = annotationView.annotation {
            
            return annotationView.configureAnnitation(annotation, delegate: self)
        }
        
        if let annotation = view.annotation as? MKUserLocation {
            
            if let placemark = annotation.placemark {
                
                view.rightCalloutAccessoryView = createSelectButton(placemark)
                
            }else{
                
                view.rightCalloutAccessoryView = nil
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        /// 只有第一次 获取用户的位置后 进行位置展示
        if !isShowUserLocation {
            
            isShowUserLocation = true
            
            mapView.showAnnotations([userLocation], animated: true)
        }
        
        if userLocationGeocoder.isGeocoding {
            
            userLocationGeocoder.cancelGeocode()
        }
        
        if let location = userLocation.location {
            
            userLocationGeocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                
                if let placemark = placemarks?.first {
                    
                    userLocation.placemark = placemark
                    
                    userLocation.title = placemark.formatStringNoBreakLine
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKind(of: MKUserLocation.self) {
            
            return nil
        }
        
        let annotationView =  mapView.dequeueReusableAnnotationView(withIdentifier: "identifer") as? PeekPinAnnotationView ?? PeekPinAnnotationView(annotation: annotation, reuseIdentifier: "identifer")
        
        annotationView.annotation = annotation
        
        return annotationView
    }
}

extension PeekViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if result == nil { return 0 }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return result?.reponse?.mapItems.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! PeekTableViewCell
        
        cell.configure(result?.reponse?.mapItems[indexPath.row], delegate: self)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.pulleyViewController?.currentDisplayMode == PulleyDisplayMode.drawer {
            self.pulleyViewController?.setDrawerPosition(position: PulleyPosition.partiallyRevealed, animated: true)
        }
        
        /// 选择 cell 高亮显示地址
        if let annptation = result?.reponse?.mapItems[indexPath.row].placemark {
            
            self.mapView.showAnnotations([annptation], animated: true)
            self.mapView.selectAnnotation(annptation, animated: true)
        }
    }
}

extension PeekViewController {
    
    class PeekAnnotation: MKPointAnnotation {
        
        /// 位置信息对象
        var placemark: CLPlacemark?
    }
}

extension PeekViewController: PeekLocationSelectedDelegate{
    
    func locationDidSelected(_ placemark: CLPlacemark) {
        
        self.pickerDelegate?.userSelectLocation(placemark: placemark)
    }
}


extension PeekViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.endEditing(true)
        
        if self.pulleyViewController?.currentDisplayMode == PulleyDisplayMode.drawer {
            self.pulleyViewController?.setDrawerPosition(position: PulleyPosition.partiallyRevealed, animated: true)
        }
        
        searchKeyWorld(searchBar.text)
    }
    
    /// show cancel button when begin edit
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchBar.setShowsCancelButton(true, animated: true)
        
        self.pulleyViewController?.setDrawerPosition(position: PulleyPosition.open, animated: true)
        
        return true
    }
    
    /// hidden cancel button when end edit
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchBar.setShowsCancelButton(false, animated: false)
        
        return true
    }
    
    /// click cancel button end editing.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.endEditing(true)
    }
}

extension PeekViewController: PulleyDrawerViewControllerDelegate {
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat{
        
        return PeekHeaderView.HEIGHT + (pulleyViewController?.currentDisplayMode == .drawer ? bottomSafeArea : 0.0)
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        
        return PulleyPosition.all
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat){
        
        tableView.isScrollEnabled = drawer.drawerPosition == .open || drawer.currentDisplayMode == .panel
        
        /// 在折叠 的时候 隐藏 边框
        if drawer.drawerPosition == .collapsed {
            bottomBorderHeightConstraint?.constant = 0
        }else{
            bottomBorderHeightConstraint?.constant = 21
        }
        
        /// 没有完全展开 就隐藏 键盘
        if drawer.drawerPosition != .open {
            headerView.searchBar.endEditing(true)
        }
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        
        /// 在 竖屏时 隐藏下方边框
        if drawer.currentDisplayMode == .drawer {
            bottomBorderHeightConstraint?.constant = 0
        }else{
            bottomBorderHeightConstraint?.constant = 21
        }
        
        self.gripperViewVConstarint?.isActive = false
        if drawer.currentDisplayMode == .drawer {
            self.gripperViewVConstarint = self.gripperView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8)
        }else{
            self.gripperViewVConstarint = self.gripperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8)
        }
        self.gripperViewVConstarint?.isActive = true
    }
}




extension PeekViewController{
    
    class PeekHeaderView: UIView{
        
        static let HEIGHT: CGFloat = 64
        
        let searchBar = UISearchBar()
        
        /// bootom border layer
        private let bottomBorderLayer = CAShapeLayer()
        
        convenience init() {
            
            self.init(frame: CGRect.zero)
            
            self.setContentCompressionResistancePriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.vertical)
            
            bottomBorderLayer.backgroundColor = UIColor.placeholderGray.cgColor
            self.layer.addSublayer(bottomBorderLayer)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            
            searchBar.returnKeyType = UIReturnKeyType.search
            
            searchBar.searchBarStyle = UISearchBar.Style.minimal
            
            addSubview(searchBar)
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            searchBar.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            searchBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            //            searchBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
            searchBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        }
        
        override func layoutSubviews() {
            
            super.layoutSubviews()
            
            bottomBorderLayer.frame = CGRect(x: 0, y: bounds.height-1, width: bounds.width, height: 1)
        }
    }
}

extension PeekViewController{
    
    class PeekBottomBorderView: UIView{
        
        /// bootom border layer
        private let bottomBorderLayer = CAShapeLayer()
        
        convenience init() {
            
            self.init(frame: CGRect.zero)
            
            clipsToBounds = true
            
            bottomBorderLayer.backgroundColor = UIColor.placeholderGray.cgColor
            self.layer.addSublayer(bottomBorderLayer)
        }
        
        override func layoutSubviews() {
            
            super.layoutSubviews()
            
            bottomBorderLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)
        }
    }
}

protocol PeekLocationSelectedDelegate: class {
    
    func locationDidSelected(_ placemark: CLPlacemark)
}

extension PeekViewController{
    
    class PeekTableViewCell: UITableViewCell {
        
        /// title
        private let titleLabel = UILabel()
        /// subTitle
        private let subTitleLabel = UILabel()
        /// select button
        private let selectedButton = UIButton(type: UIButton.ButtonType.system)
        
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        private var item: MKMapItem?
        
        weak var delegate: PeekLocationSelectedDelegate?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            backgroundColor = UIColor.clear
            
            titleLabel.numberOfLines = 0
            subTitleLabel.numberOfLines = 0
            
            selectedButton.addTarget(self, action: #selector(buttonClickMethod), for: UIControl.Event.touchUpInside)
            selectedButton.setAttributedTitle("选定".font(UIFont.boldSystemFont(ofSize: 14)), for: UIControl.State.normal)
            /// selectedButton layout
            selectedButton.setContentCompressionResistancePriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
            selectedButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
            contentView.addSubview(selectedButton)
            selectedButton.translatesAutoresizingMaskIntoConstraints = false
            selectedButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            selectedButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            selectedButton.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
            
            /// titleLabel layout
            contentView.addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
            titleLabel.rightAnchor.constraint(equalTo: selectedButton.rightAnchor, constant: -10).isActive = true
            
            /// subTitleLabel layout
            contentView.addSubview(subTitleLabel)
            subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
            subTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
            subTitleLabel.rightAnchor.constraint(equalTo: selectedButton.rightAnchor, constant: -10).isActive = true
            subTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        }
        
        func configure(_ item: MKMapItem?, delegate: PeekLocationSelectedDelegate) {
            
            self.item = item
            self.delegate = delegate
            
            titleLabel.attributedText = item?.name?.font(UIFont.boldSystemFont(ofSize: 20))
            subTitleLabel.attributedText = item?.placemark.formatString.font(UIFont.boldSystemFont(ofSize: 13)).textColor(UIColor.lightGray)
        }
        
        @objc private func buttonClickMethod(){
            guard let item = self.item else { return }
            self.delegate?.locationDidSelected(item.placemark)
        }
    }
}


extension String{
    
    func textColor(_ color: UIColor) -> NSAttributedString{
        return NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.foregroundColor : color])
    }
    
    func font(_ font: UIFont) -> NSAttributedString{
        return NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.font : font])
    }
}

extension NSAttributedString {
    
    func textColor(_ color: UIColor) -> NSAttributedString{
        let attributeString = NSMutableAttributedString(attributedString: self)
        attributeString.addAttributes([NSAttributedString.Key.foregroundColor : color], range: NSRange(location: 0, length: self.string.count))
        return attributeString
    }
    
    func font(_ font: UIFont) -> NSAttributedString{
        let attributeString = NSMutableAttributedString(attributedString: self)
        attributeString.addAttributes([NSAttributedString.Key.font : font], range: NSRange(location: 0, length: self.string.count))
        return attributeString
    }
}

import AddressBookUI
import Contacts

extension MKUserLocation{
    
    /// Runtime 键
    private struct AssociatedKeys {
        
        static var placemark: UInt8 = 0
    }
    
    var placemark: CLPlacemark? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.placemark) as? CLPlacemark
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.placemark, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension CLPlacemark {
    
    /// 格式化字符串
    public var formatString: String{
        return CNPostalAddressFormatter().string(from: CNMutablePostalAddress(placemark: self))
    }
    
    /// 没有回车的格式化 视图
    public var formatStringNoBreakLine: String{
        return CNPostalAddressFormatter().string(from: CNMutablePostalAddress(placemark: self)).replacingOccurrences(of: "\n", with: " ")
    }
}

extension CNMutablePostalAddress {
    convenience init(placemark: CLPlacemark) {
        self.init()
        street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }           // remove nils, so that...
            .joined(separator: " ")      // ...only if both != nil, add a space.
        /*
         // Equivalent street assignment, w/o flatMap + joined:
         if let subThoroughfare = placemark.subThoroughfare,
         let thoroughfare = placemark.thoroughfare {
         street = "\(subThoroughfare) \(thoroughfare)"
         } else {
         street = (placemark.subThoroughfare ?? "") + (placemark.thoroughfare ?? "")
         }
         */
        city = placemark.locality ?? ""
        state = placemark.administrativeArea ?? ""
        postalCode = placemark.postalCode ?? ""
        country = placemark.country ?? ""
        isoCountryCode = placemark.isoCountryCode ?? ""
        if #available(iOS 10.3, *) {
            subLocality = placemark.subLocality ?? ""
            subAdministrativeArea = placemark.subAdministrativeArea ?? ""
        }
    }
}


extension CLError {
    
    var pickerdescription: String {
        switch self.code {
        case .locationUnknown:
            return NSLocalizedString("Location Unknown", comment: "")
        case .denied:
            return NSLocalizedString("Authorization Denied", comment: "")
        case .headingFailure:
            return NSLocalizedString("Heading Failure", comment: "")
        case .network:
            return NSLocalizedString("Network Problem", comment: "")
        case .regionMonitoringDenied:
            return NSLocalizedString("Denied Region Monitoring", comment: "")
        case .regionMonitoringFailure:
            return NSLocalizedString("Failed Region Monitoring", comment: "")
        case .regionMonitoringSetupDelayed:
            return NSLocalizedString("Delayed Setup Region Monitoring", comment: "")
        case .regionMonitoringResponseDelayed:
            return NSLocalizedString("Delayed Response Region Monitoring", comment: "")
        case .geocodeFoundNoResult:
            return NSLocalizedString("No Result Compatible", comment: "")
        case .geocodeFoundPartialResult:
            return NSLocalizedString("Partial Result Compatible", comment: "")
        case .geocodeCanceled:
            return NSLocalizedString("Canceled Compatible", comment: "")
        case .deferredFailed:
            return NSLocalizedString("Deferred Failed", comment: "")
        case .deferredNotUpdatingLocation:
            return NSLocalizedString("Deferred Not Updating Location", comment: "")
        case .deferredAccuracyTooLow:
            return NSLocalizedString("Deferred Accuracy Too Low", comment: "")
        case .deferredDistanceFiltered:
            return NSLocalizedString("Deferred Distance Filtered", comment: "")
        case .deferredCanceled:
            return NSLocalizedString("Deferred Canceled", comment: "")
        case .rangingUnavailable:
            return NSLocalizedString("Ranging Unavailable", comment: "")
        case .rangingFailure:
            return NSLocalizedString("Ranging Failure", comment: "")
        @unknown default: return ""
        }
    }
}

extension MKError {
    
    var pickerdescription: String {
        switch self.code {
        case .unknown:
            return NSLocalizedString("Unknown Error", comment: "")
        case .serverFailure:
            return NSLocalizedString("Server Failure", comment: "")
        case .loadingThrottled:
            return NSLocalizedString("Loading Throttled", comment: "")
        case .placemarkNotFound:
            return NSLocalizedString("Placemark Not Found", comment: "")
        case .directionsNotFound:
            return NSLocalizedString("Directions Not Found", comment: "")
        @unknown default: return ""
        }
    }
}

extension UIDevice{
    
    var safeAreaInsets: UIEdgeInsets{
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets ?? UIEdgeInsets.zero
        } else {
            return UIEdgeInsets.zero
        }
    }
}

extension UIColor {
    static var placeholderGray: UIColor {
        return UIColor(red: 0.780, green: 0.780, blue: 0.803, alpha: 0.22)
    }
}

class ClosureSleeve {
    let closure: () -> ()
    
    init(attachTo: AnyObject, closure: @escaping () -> ()) {
        self.closure = closure
        objc_setAssociatedObject(attachTo, "[\(arc4random())]", self, .OBJC_ASSOCIATION_RETAIN)
    }
    
    @objc func invoke() {
        closure()
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .primaryActionTriggered, action: @escaping () -> ()) {
        let sleeve = ClosureSleeve(attachTo: self, closure: action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
    }
}


extension UIViewController{
    
    /// 展示一个弹出框
    ///
    /// - Parameter message: 消息
    func showMessage(_ message: String){
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "好的", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
