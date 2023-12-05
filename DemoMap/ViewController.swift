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

class ViewController: UIViewController {
    var mapView = GMSMapView()
    let geocoder = GMSGeocoder()
    let marker = GMSMarker()
    let locationManager = CLLocationManager()
    let location = CLLocation()
    let mapTypes: [GMSMapViewType] = [.hybrid, .normal, .satellite]
    var currentMapTypeIdx = 0
    
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
        
//        let camera = GMSCameraPosition.camera(withTarget: dummyLocation, zoom: 16.0)
//        mapView.camera = camera
//        locations = getMockLocationsFor(location: CLLocation(latitude: dummyLocation.latitude, longitude: dummyLocation.longitude), itemCount: 200)
    }
    
    func getMockLocationsFor(location: CLLocation, itemCount: Int) -> [CLLocation] {
        
        func getBase(number: Double) -> Double {
            return round(number * 1000)/1000
        }
        
        func randomCoordinate() -> Double {
            return Double(arc4random_uniform(140)) * 0.0001
        }
        
        let baseLatitude = getBase(number: location.coordinate.latitude - 0.007)
        let baseLongitude = getBase(number: location.coordinate.longitude - 0.008)
        
        var items: [CLLocation] = []
        
        for _ in 0 ..< itemCount {
            let randomLat = baseLatitude + randomCoordinate()
            let randomLong = baseLongitude + randomCoordinate()
            let location = CLLocation(latitude: randomLat, longitude: randomLong)
            
            items.append(location)
        }
        
        return items
    }

    
    func drawPolygon() {
        let path = GMSMutablePath()
        path.add(CLLocationCoordinate2D(latitude: 19.017615, longitude: 72.856174))
        path.add(CLLocationCoordinate2D(latitude: 19.117624, longitude: 72.856174))
        path.add(CLLocationCoordinate2D(latitude: 19.117624, longitude: 72.956184))
        path.add(CLLocationCoordinate2D(latitude: 19.017615, longitude: 72.956184))
        path.add(CLLocationCoordinate2D(latitude: 19.017615, longitude: 72.856174))
        
        let polygon = GMSPolygon(path: path)
        polygon.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.01);
        polygon.map = mapView
        
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = .red
        polyline.strokeWidth = 5
        polyline.map = mapView
    }
    
    func setupMapView() {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: 20.5937, longitude: 78.9629, zoom: 3.0)
        options.frame = view.bounds
        
        mapView = GMSMapView(options: options)
        mapView.delegate = self
        locationManager.delegate = self
        
        mapView.mapType = .hybrid
        mapView.isTrafficEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        locationManager.startUpdatingLocation()
        
        view.addSubview(mapView)
        mapView.addSubview(mapButton)
        mapView.addSubview(buttonDraw)
        
        // Activate constraints for mapButton
        NSLayoutConstraint.activate([
            mapButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 60),
            mapButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            mapButton.widthAnchor.constraint(equalToConstant: 60),
            mapButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Activate constraints for buttonDraw
        NSLayoutConstraint.activate([
            buttonDraw.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant:125),
            buttonDraw.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            buttonDraw.widthAnchor.constraint(equalToConstant: 60),
            buttonDraw.heightAnchor.constraint(equalToConstant: 60)
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
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        if let title = marker.title {
            if let snippet = marker.snippet {
                print("marker title: \(title): snippet: \(snippet)")
            }
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "DemoViewController") as! DemoViewController
            vc.titleText = title
            
            vc.modalPresentationStyle = .fullScreen
            
            present(vc, animated: true)
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
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40)) // Adjust si4e as needed
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        
        // Create a label for the text
        let label = UILabel(frame: CGRect(x: 0, y: imageView.frame.size.height + 10, width: 60, height: 20)) // Adjust label size as needed
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = UIColor.white // Adjust label background color
        label.layer.cornerRadius = 5 // Adjust corner radius for label
        label.layer.masksToBounds = true // Clip to bounds
        
        // Create a view to hold both imageView and label
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 80)) // Adjust iconView size as needed
        iconView.addSubview(imageView)
        iconView.addSubview(label)
        
        // Center imageView within iconView
        imageView.center = CGPoint(x: iconView.bounds.midX, y: iconView.bounds.midY - (label.frame.size.height / 2))
        
        // Set label position below imageView
        label.frame.origin.y = imageView.frame.maxY
        
        UIGraphicsBeginImageContextWithOptions(iconView.bounds.size, false, 0.0)
        iconView.layer.render(in: UIGraphicsGetCurrentContext()!)
        iconView.isUserInteractionEnabled = true
        
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: )
//        iconView.addGestureRecognizer(tapGesture)
        
        let markerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        marker.icon = markerImage
        
        marker.appearAnimation = .pop

        clusterManager.add(marker)
        clusterManager.cluster()
    }
}

extension ViewController: GMUClusterManagerDelegate {
    private func setupCluster() {
        guard let mapView: GMSMapView? = self.mapView else { return }
        
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView!, clusterIconGenerator: iconGenerator)
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
            
            if drawableLoc.count > 2 {
                let coordinateBounds = GMSCoordinateBounds(path: newpolygon.path!)
                
                // Adjust map zoom to the polygon that has been drawn to the screen
                mapView.animate(with: .fit(coordinateBounds))
            }
        }
    }
}

extension ViewController {
    // Get Marker Inside polygon
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












//class MapClusterIconGenerator: GMUDefaultClusterIconGenerator {
//
//    override func icon(forSize size: UInt) -> UIImage {
//        let image = textToImage(drawText: String(size) as NSString,
//                                inImage: UIImage(systemName: "map")!,
//                                font: UIFont.systemFont(ofSize: 15), tintColor: UIColor.white)
//        return image ?? UIImage()
//    }
//
//    private func textToImage(drawText text: NSString, inImage image: UIImage, font: UIFont, tintColor: UIColor) -> UIImage? {
//        let imageWidth = image.size.width
//        let imageHeight = image.size.height
//
//        // Define the space for the text below the image
//        let extraSpaceHeight: CGFloat = 20
//
//        let newImageHeight = imageHeight + extraSpaceHeight
//
//        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageWidth, height: newImageHeight), false, image.scale)
//
//        // Draw the original image
//        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
//
//        // Tint the original image
//        if let tintedImage = tintImage(image, color: tintColor) {
//            tintedImage.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
//        }
//
//        let textStyle = NSMutableParagraphStyle()
//        textStyle.alignment = NSTextAlignment.center
//        let textColor = UIColor.white
//        let attributes: [NSAttributedString.Key: Any] = [
//            .font: font,
//            .paragraphStyle: textStyle,
//            .foregroundColor: textColor
//        ]
//
//        let textSize = text.size(withAttributes: attributes)
//
//        // Calculate the text's vertical position below the image
//        let textY = imageHeight + ((extraSpaceHeight - textSize.height) / 2)
//
//        // Draw text below the image
//        let textRect = CGRect(x: 0, y: textY, width: imageWidth, height: textSize.height)
//        text.draw(in: textRect.integral, withAttributes: attributes)
//
//        let result = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return result
//    }
//
//    // Function to tint an image with a color
//    func tintImage(_ image: UIImage, color: UIColor) -> UIImage? {
//        return image.withRenderingMode(.alwaysTemplate).tint(with: color)
//    }
//
//}

//extension UIImage {
//    func tint(with color: UIColor) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//        guard let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage else {
//            return nil
//        }
//        
//        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        context.setBlendMode(.normal)
//        context.translateBy(x: 0, y: size.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//        context.setFillColor(color.cgColor)
//        context.fill(rect)
//        
//        context.setBlendMode(.destinationIn)
//        context.draw(cgImage, in: rect)
//        
//        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        return tintedImage
//    }
//}
