//
//  ViewController.swift
//  DemoMap
//
//  Created by Gaurav Sara on 29/11/23.
//

import UIKit
import GoogleMaps
import CoreLocation
import GoogleMapsUtils

struct Person {
    let name: String
    let age: Int
    let height: Double
}

class ViewController: UIViewController {
    @IBOutlet var mapView: GMSMapView!
    let geocoder = GMSGeocoder()
    let marker = GMSMarker()
    let locationManager = CLLocationManager()
    let location = CLLocation()
    let mapTypes: [GMSMapViewType] = [.hybrid, .normal, .satellite]
    var currentMapTypeIdx = 0
    var customView: Viewn!
    var isPolygonHidden: Bool = false
    
    var clusterManager: GMUClusterManager!
    var drawCoordinates: [CLLocationCoordinate2D] = []
    var locations: [CLLocation] = [] {
        didSet {
            if !locations.isEmpty {
                generateMarkers()
            }
        }
    }
    
    var polygonPath: GMSMutablePath = GMSMutablePath()
    var polygon: GMSPolygon?
    var isDrawing: Bool = false
    var markersInsideShape: [GMSMarker] = []
    var randomMarkers: [GMSMarker] = []
    var userDrawablePolygons: [GMSPolygon] = []
    let dummyLocation = CLLocationCoordinate2D(latitude: CLLocationDegrees(19.017615), longitude: CLLocationDegrees(72.856174))
    
    var mapButton: UIButton = {
        let button = UIButton(type: .system)
        let width: Float = 100
        
        button.setImage(UIImage(systemName: "map"), for: .normal)
        button.frame.size.width = CGFloat(width)
        button.addTarget(self, action: #selector(changeMapType), for: .touchUpInside)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = CGFloat(width / 3)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var buttonDraw: UIButton = {
        let button = UIButton(type: .system)
        let width: Float = 100
        
        button.setImage(UIImage(systemName: "pencil.line"), for: .normal)
        button.frame.size.width = CGFloat(width)
        button.addTarget(self, action: #selector(buttonDrawTapped), for: .touchUpInside)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = CGFloat(width / 3)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var hideCanvasBtn: UIButton = {
        let button = UIButton(type: .system)
        let width: Float = 100
        
        button.setImage(UIImage(systemName: "pencil.line"), for: .normal)
        button.frame.size.width = CGFloat(width)
        button.addTarget(self, action: #selector(hidePolygon), for: .touchUpInside)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = CGFloat(width / 3)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var canvasView: CanvasView = {
        var overlayView = CanvasView(frame: self.mapView.frame)
        overlayView.isUserInteractionEnabled = true
        overlayView.delegate = self
        return overlayView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupCluster()
        clusterManager.setMapDelegate(self)
        loadPolygon()
    }
    
    func drawPolygon(_ coordinates: [CLLocationCoordinate2D]) {
        let path = GMSMutablePath()

        for coordinate in coordinates {
            path.add(coordinate)
        }

        let newpolygon = GMSPolygon(path: path)
        newpolygon.strokeWidth = 3
        newpolygon.strokeColor = UIColor(red: 20.0/255.0, green: 119.0/255.0, blue: 234.0/255.0, alpha: 0.75)
        newpolygon.fillColor = UIColor(red: 156.0/255.0, green: 202.0/255.0, blue: 254.0/255.0, alpha: 0.4)
        newpolygon.map = mapView
        userDrawablePolygons.append(newpolygon)
    }
    
    func setupMapView() {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: 20.5937, longitude: 78.9629, zoom: 10.0)
        options.frame = view.bounds
        
        mapView = GMSMapView(options: options)
        mapView.delegate = self
        locationManager.delegate = self
        
        mapView.mapType = .hybrid
        mapView.isTrafficEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        self.view = mapView
        
        locationManager.startUpdatingLocation()
        
        mapView.addSubview(mapButton)
        mapView.addSubview(buttonDraw)
        mapView.addSubview(hideCanvasBtn)
        
        NSLayoutConstraint.activate([
            mapButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 60),
            mapButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            mapButton.widthAnchor.constraint(equalToConstant: 60),
            mapButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        NSLayoutConstraint.activate([
            buttonDraw.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant:125),
            buttonDraw.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            buttonDraw.widthAnchor.constraint(equalToConstant: 60),
            buttonDraw.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        NSLayoutConstraint.activate([
            hideCanvasBtn.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant:220),
            hideCanvasBtn.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            hideCanvasBtn.widthAnchor.constraint(equalToConstant: 60),
            hideCanvasBtn.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc func changeMapType(_ sender: UIButton) {
        currentMapTypeIdx += 1
        
        if currentMapTypeIdx > mapTypes.count - 1 {
            currentMapTypeIdx = 0
        }
        
        mapView.mapType = mapTypes[currentMapTypeIdx]
    }
    
    @objc func buttonDrawTapped(_ sender: UIButton) {
        isDrawing = !isDrawing
        if isDrawing {
            buttonDraw.setImage(UIImage(systemName: "multiply"), for: .normal)
            // Prepare to draw
            mapView.addSubview(canvasView)
            mapView.willRemoveSubview(buttonDraw)
            mapView.addSubview(buttonDraw)
        } else {
            buttonDraw.setImage(UIImage(systemName: "pencil.line"), for: .normal)
            resetMapView()
            isDrawing = false
            mapView.reloadInputViews()
        }
    }
    
    @objc func hidePolygon(_ sender: UIButton) {
        isPolygonHidden.toggle()
        
        if isPolygonHidden {
            for polygon in userDrawablePolygons {
                polygon.map = nil
            }
        } else {
            for polygon in userDrawablePolygons {
                polygon.map = mapView
            }
        }
    }
    
    func resetMapView() {
        userDrawablePolygons.removeAll()
        markersInsideShape.removeAll()
        locations.removeAll()
        randomMarkers.removeAll()
        mapView.clear()
        
        clusterManager.clearItems()
        clusterManager.cluster()

        if !locations.isEmpty {
            generateMarkers()
        }
    }
}

extension ViewController: CLLocationManagerDelegate, GMSMapViewDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        let coordinate = location.coordinate
        
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude,
                                              longitude: coordinate.longitude,
                                              zoom: 20)
        
        mapView.animate(to: camera)
        addMarker(at: coordinate)
        
        locationManager.stopUpdatingLocation()
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
            addMarker(at: coordinate)
    }
    
    // Events to track zoom level
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        let zoomLevel = position.zoom
        
        if position.zoom > 12 {
            print(position.zoom)
            
        } else {
            print(position.zoom)
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let cluster = marker.userData as? GMUCluster {
            let newCamera = GMSCameraPosition.camera(withTarget: marker.position, zoom: mapView.camera.zoom + 1)
            let update = GMSCameraUpdate.setCamera(newCamera)
            mapView.moveCamera(update)
        } else {
            if let title = marker.title {
                if let snippet = marker.snippet {
                    print("marker title: \(title): snippet: \(snippet)")
                }
                
                let vc = storyboard?.instantiateViewController(withIdentifier: "DemoViewController") as! DemoViewController
                vc.titleText = title
                vc.me = Person(name: "Gaurav", age: 36, height: 5.8)
                
                vc.modalPresentationStyle = .fullScreen
                
                present(vc, animated: true)
            }
        }
        return true
    }
}

// MARK - Add Custom Marker as well as add marker to the clusterManager
extension ViewController {
    func addMarker(at coordinate: CLLocationCoordinate2D) {
        let pinImage = UIImage(named: "40") ?? UIImage()
        
        marker.position = coordinate
        
        geocoder.reverseGeocodeCoordinate(coordinate) { (response, error) in
            guard error == nil else { return }
            
            if let result = response?.firstResult() {
                self.marker.title = result.lines?.first
                self.markerWithImageAndText(image: pinImage, text: self.marker.title ?? "", position: coordinate, mapView: self.mapView)
            }
        }
    }
    
    func markerWithImageAndText(image: UIImage, text: String, position: CLLocationCoordinate2D, mapView: GMSMapView) {
        let marker = GMSMarker(position: position)
        marker.title = text
        
        // Create an imageView for the image
//        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
//        imageView.image = image
//        imageView.contentMode = .scaleAspectFit
//        
//        // Create a label for the text
//        let label = UILabel(frame: CGRect(x: 0, y: imageView.frame.size.height + 10, width: 150, height: 20))
//        label.text = text
//        label.textColor = UIColor.white
//        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
//        label.textAlignment = .center
//        label.backgroundColor = UIColor.clear
//        label.layer.cornerRadius = 5
//        label.layer.masksToBounds = true
//        
//        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 80))
//        iconView.addSubview(imageView)
//        iconView.addSubview(label)
//        
//        imageView.center = CGPoint(x: iconView.bounds.midX, y: iconView.bounds.midY - (label.frame.size.height / 2))
//        
//        label.frame.origin.y = imageView.frame.maxY
//        
//        UIGraphicsBeginImageContextWithOptions(iconView.bounds.size, false, 0.0)
//        iconView.layer.render(in: UIGraphicsGetCurrentContext()!)
//        iconView.isUserInteractionEnabled = true
//        
//        let markerImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
        
//        marker.icon = markerImage
        
        let customView = Viewn.loadView()
        let image = UIImage(named: "40")
        customView.setupUI(image: image ?? UIImage(), imageText: text)
        marker.iconView = customView
        
        marker.appearAnimation = .pop

        clusterManager.add(marker)
        clusterManager.cluster()
    }
}

extension ViewController {
    private func setupCluster() {
        guard let mapView: GMSMapView? = self.mapView else { return }
        
        var iconGenerator: GMUDefaultClusterIconGenerator!
        
        let image = UIImage(named: "40s")
        
        let images = [image!, image!, image!]
        iconGenerator = GMUDefaultClusterIconGenerator(buckets: [5, 10, 20], backgroundImages: images)
        let renderer = GMUDefaultClusterRenderer(mapView: mapView!, clusterIconGenerator: iconGenerator)
        // control clustering on specific zoom level
        renderer.maximumClusterZoom = 20
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        clusterManager = GMUClusterManager(map: mapView!, algorithm: algorithm, renderer: renderer)
    }
}

// MARK: Create Polygon
extension ViewController {
    func createPolygonFromTheDrawablePoints() {
        let numberOfPoints = self.drawCoordinates.count
        
        /// Do not draw in mapview a single point
        if numberOfPoints > 2 {
            addPolyGonInMapView(drawableLoc: drawCoordinates)
            drawCoordinates = []
            self.canvasView.image = nil
            self.canvasView.removeFromSuperview()
        }
    }
    
    func addPolyGonInMapView(drawableLoc: [CLLocationCoordinate2D]) {
        if isDrawing {
            let path = GMSMutablePath()
            
            for loc in drawableLoc {
                path.add(loc)
            }
            
            let newpolygon = GMSPolygon(path: path)
            newpolygon.strokeWidth = 3
            newpolygon.strokeColor = UIColor(red: 20.0/255.0, green: 119.0/255.0, blue: 234.0/255.0, alpha: 0.75)
            newpolygon.fillColor = UIColor(red: 156.0/255.0, green: 202.0/255.0, blue: 254.0/255.0, alpha: 0.4)
            newpolygon.map = mapView
            userDrawablePolygons.append(newpolygon)
            
            // Save the polygon coordinates
            savePolygon(coordinates: drawableLoc)
            
            if drawableLoc.count > 2 {
                let coordinateBounds = GMSCoordinateBounds(path: newpolygon.path!)
                
                mapView.animate(with: .fit(coordinateBounds))
            }
        }
    }
}

extension ViewController {
    func getMarkerInsidePolygon() {
        if userDrawablePolygons.count <= 0 {
            return
        }
        
        let myPolygon = userDrawablePolygons[0].path
        markersInsideShape.removeAll()
        
        // Validate all markers that are not included in the polygon and delete from the map
        for marker in randomMarkers {
            if (GMSGeometryContainsLocation(marker.position, myPolygon!, true)) {
                markersInsideShape.append(marker)
            } else {
                marker.map = nil
            }
        }
    }
    
    func generateMarkers() {
        for location in locations {
            let position = location.coordinate
            addMarker(at: position)
            randomMarkers.append(marker)
        }
    }
}

extension ViewController: NotifyTouchEvents {
    func touchBegan(touch: UITouch) {
        self.drawCoordinates.append(self.translateCoordinate(withTouch: touch))
    }
    
    func touchMoved(touch: UITouch) {
        self.drawCoordinates.append(self.translateCoordinate(withTouch: touch))
    }
    
    func touchEnded(touch: UITouch) {
        self.drawCoordinates.append(self.translateCoordinate(withTouch: touch))
        createPolygonFromTheDrawablePoints()
        getMarkerInsidePolygon()
    }
    
    func translateCoordinate(withTouch touch: UITouch) -> CLLocationCoordinate2D {
        let location = touch.location(in: self.mapView)
        return self.mapView.projection.coordinate(for: location)
    }
}

// Retrive polygon
extension ViewController {
    func savePolygon(coordinates: [CLLocationCoordinate2D]) {
        // Array of dictionaries for saving
        let polyCoordinates = coordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        
        // Save the coordinates array to UserDefaults
        UserDefaults.standard.set(polyCoordinates, forKey: "polygonCoordinates")
    }
    
    func loadPolygon() {
        // Retrieve coordinates from UserDefaults
        if let savedCoordinates = UserDefaults.standard.array(forKey: "polygonCoordinates") as? [[String: Double]] {
            drawCoordinates = savedCoordinates.map {
                CLLocationCoordinate2D(latitude: $0["latitude"] ?? 0.0, longitude: $0["longitude"] ?? 0.0)
            }
            
            // Create a polygon from the saved coordinates
            drawPolygon(drawCoordinates)
        }
    }
}
