//
//  MapViewController.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 10.01.23.
//

import UIKit
import MapKit
import SnapKit
import Kingfisher

class MapViewController: UIViewController, MKMapViewDelegate {
  public var userId = Int()
  public var vehicles: [UserVehicle] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let mapView = MKMapView()
    self.view.addSubview(mapView)
    mapView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    mapView.delegate = self
    
    let unauthorizedNetworkManager = UnauthorizedNetworkManager(plugins: [])
    unauthorizedNetworkManager.processUserCars(
      uuid: UUID(),
      params: String(userId),
      onSuccess: CommandWith { response in
        if let vCoordinates = response.data, self.vehicles.count == vCoordinates.count {
          var locations: [Location] = []
          var c = 0
          for (veh, coord) in zip(self.vehicles, vCoordinates) {
            locations.append(Location(name: "Model: \(String(describing: veh.name)), color: \(String(describing: veh.color))",
                                      identifier: String(c),
                                      lat: coord.lat,
                                      long: coord.lon)
            )
            c += 1
          }
          mapView.addAnnotations(locations)
        }
        
      },
      onFail: CommandWith { response in
        print("failed processUserCars")
      }
    )
  }
  
  
}

extension MapViewController {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? Location{
      if let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.identifier){
        return view
      }else{
        let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.identifier)
        if let id = Int(annotation.identifier), let vechUrl = self.vehicles[id].foto {
          self.downloadImage(with: vechUrl) { image in
            guard let image  = image else { return }
            view.image = self.resizeImage(image: image, newWidth: 30.0)
          }
        }
        view.isEnabled = true
        view.canShowCallout = true
        return view
      }
    }
    return nil
  }
  
  func downloadImage(with urlString : String , imageCompletionHandler: @escaping (UIImage?) -> Void){
    guard let url = URL.init(string: urlString) else {
      return  imageCompletionHandler(nil)
    }
    let resource = ImageResource(downloadURL: url)
    
    KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
      switch result {
        case .success(let value):
          imageCompletionHandler(value.image)
        case .failure:
          imageCompletionHandler(nil)
      }
    }
  }
  
  func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
}

struct UserVehicle {
  public let foto: String?
  public let name: String?
  public let addres: String?
  public let color: String?
}

class Location: NSObject, MKAnnotation {
  var identifier: String
  var title: String?
  var coordinate: CLLocationCoordinate2D
  init(name:String, identifier: String, lat:CLLocationDegrees, long:CLLocationDegrees){
    title = name
    self.identifier = identifier
    coordinate = CLLocationCoordinate2DMake(lat, long)
  }
}
