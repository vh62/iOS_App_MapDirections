//
//  MainController.swift
//  MapDirectionsGooglePlaces
//
//  Created by Vikram Ho on 1/21/21.
//

import UIKit
import MapKit
import SwiftUI
import LBTATools

extension MainController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if(annotation is MKPointAnnotation){
            
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            annotationView.canShowCallout = true
            return annotationView
        }
        return nil
    }
}

class MainController: UIViewController, CLLocationManagerDelegate{
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestUserLocation()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        mapView.fillSuperview()
        
        
        setupRegionForMap()
//        setupAnnotationsForMap()
        performLocalSearch()
        setupSearchUI()
        setupLocationsCarousel()
        locationsController.mainController = self
        setupSearchListener()
        
    }
    
    fileprivate func requestUserLocation(){
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .authorizedWhenInUse:
            print("Received authorization of user location")
            locationManager.startUpdatingLocation()
        default:
            print("Failed to authorize")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else { return }
        mapView.setRegion(.init(center: firstLocation.coordinate,span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
        
        locationManager.stopUpdatingLocation()
    }
    
    let locationsController = LocationCarouselController(scrollDirection: .horizontal)
    
    fileprivate func setupLocationsCarousel(){
        
        let locationsView = locationsController.view!
        
        view.addSubview(locationsView)
        locationsView.anchor(
            top     : nil,
            leading : view.leadingAnchor,
            bottom  : view.safeAreaLayoutGuide.bottomAnchor,
            trailing: view.trailingAnchor,
//            padding : .init(top: 0, left: 16, bottom: 0, right: 16),
            size    : .init(width: 0, height: 150))
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let customAnnotation = view.annotation as? CustomMapItemAnnotation else { return }
                
        guard let index = self.locationsController.items.firstIndex(where: {$0.name == customAnnotation.mapItem?.name}) else { return }
        
        self.locationsController.collectionView.scrollToItem(at: [0,index], at: .centeredHorizontally, animated: true)
    }
    
    let searchTextField = UITextField(placeholder: "Search Query")
    
    fileprivate func setupSearchUI(){
        
        let whiteContainer = UIView(backgroundColor: .white)
        view.addSubview(whiteContainer)
        
        whiteContainer.anchor(
            top     : view.safeAreaLayoutGuide.topAnchor,
            leading : view.leadingAnchor,
            bottom  : nil,
            trailing: view.trailingAnchor,
            padding : .init(top: 0, left: 16, bottom: 0, right: 16)
            )
        whiteContainer.stack(searchTextField).withMargins(.allSides(16))
    }
    
    var listener: Any!
    
    fileprivate func setupSearchListener(){
        listener = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: searchTextField)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] (_) in
                self?.performLocalSearch()
                print(123456)
            }
    }
    
    @objc fileprivate func handleSearchChanges(){
        performLocalSearch()
    }
    
    fileprivate func performLocalSearch(){
        
        let request     = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTextField.text
        request.region = mapView.region
        
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (response, error) in
            if let error = error {
                print("failed local search: ", error)
                return
            }
            
            //Success
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.locationsController.items.removeAll()
            response?.mapItems.forEach({ (mapItem) in
                print(mapItem.displayAddress())
               
                
                let annotation = CustomMapItemAnnotation()
                annotation.mapItem = mapItem
                annotation.coordinate = mapItem.placemark.coordinate
                annotation.title = "Location: " + (mapItem.name ?? "")
                
                self.mapView.addAnnotation(annotation)
                
                self.locationsController.items.append(mapItem)
            })
            
            self.locationsController.collectionView.scrollToItem(at: [0,0], at: .centeredHorizontally, animated: true)
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    class CustomMapItemAnnotation: MKPointAnnotation{
        var mapItem: MKMapItem?
        
    }

    
    fileprivate func setupAnnotationsForMap(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 40.780265, longitude: -73.965806)
        annotation.title = "New York"
        annotation.subtitle = "Central Park"
        mapView.addAnnotation(annotation)
        
        let rockerfeller_center = MKPointAnnotation()
        rockerfeller_center.coordinate = CLLocationCoordinate2D(latitude: 40.75889458686454, longitude: -73.9786736016866)
        rockerfeller_center.title = "Rockerfeller center"
        mapView.addAnnotation(rockerfeller_center)
        
        mapView.showAnnotations(self.mapView.annotations, animated: true)
    }
    
    fileprivate func setupRegionForMap(){
        let centerCoordinate = CLLocationCoordinate2D(latitude: 40.780265, longitude: -73.965806)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}

extension MKMapItem{
    func displayAddress() -> String{
        var addressString = ""
        if let number = placemark.subThoroughfare,
           let street = placemark.thoroughfare,
           let zip    = placemark.postalCode,
           let city   = placemark.locality,
           let state  = placemark.administrativeArea
        {
            addressString = "\(number) \(street), \(city), \(state) \(zip)"
        }
        return addressString
    }
}
struct MainPreView: PreviewProvider{
    static var previews: some View{
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable{
        func makeUIViewController(context: Context) -> MainController {
            return MainController()
        }
        
        func updateUIViewController(_ uiViewController: MainController, context: Context) {
            
        }
        typealias UIViewControllerType = MainController
        
    }
}
