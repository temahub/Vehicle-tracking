//
//  ViewController.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 21.12.22.
//

import UIKit
import Kingfisher

class MainViewController: UIViewController, UICollectionViewDelegate, UITextViewDelegate {
  var collectionView: UICollectionView!
  private lazy var dataSource = makeDataSource()
  var users: [User] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    self.view.addSubview(collectionView)
    
    collectionView.delegate = self
    collectionView.dataSource = dataSource
    
    setData(animated: true)
    
    let unauthorizedNetworkManager = UnauthorizedNetworkManager(plugins: [])
    unauthorizedNetworkManager.processUsersList(
      uuid: UUID(),
      onSuccess: CommandWith { response in
        let nonNilUsers = response.data.compactMap { $0 }
        for user in nonNilUsers {
          self.users.append(User(userid: user.userid, owner: user.owner, vehicles: user.vehicles))
          self.setData(animated: true)
        }
      },
      onFail: CommandWith { response in
        print("failed")
      }
    )
  }
  
  func setData(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
    snapshot.appendSections(Section.allCases)
    snapshot.appendItems(users)
    dataSource.apply(snapshot, animatingDifferences: animated)
  }
  
  func makeDataSource() -> UICollectionViewDiffableDataSource<Section, User> {
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, User> { cell, indexPath, user in
      var content = cell.defaultContentConfiguration()
      cell.isUserInteractionEnabled = true
      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
      cell.addGestureRecognizer(longPressRecognizer)
      
      if user.showDetails{
        content.text = user.name
        content.secondaryText = user.body
        if let url = user.owner?.foto {
          self.downloadImage(with: url) { image in
            guard let image  = image else { return }
            content.image = self.resizeImage(image: image, newWidth: 30.0)
          }
        }
      }
      else{
        content.text = user.name
      }
      cell.contentConfiguration = content
    }
    
    return UICollectionViewDiffableDataSource<Section, User>(
      collectionView: collectionView,
      cellProvider: { collectionView, indexPath, item in
        collectionView.dequeueConfiguredReusableCell(
          using: cellRegistration,
          for: indexPath,
          item: item
        )
      }
    )
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    
    
    guard let user = dataSource.itemIdentifier(for: indexPath) else {
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }
    
    user.showDetails.toggle()
    var currentSnapshot = dataSource.snapshot()
    
    currentSnapshot.reconfigureItems([user])
    dataSource.apply(currentSnapshot)
    
    collectionView.deselectItem(at: indexPath, animated: true)
    
  }
  
  enum Section : CaseIterable {
    case one
    case two
  }
  
  class User: Hashable {
    var userid: Int?
    var owner: Owner?
    var vehicles: [Vehicle?]?
    var showDetails = false
    var name: String = "N/A"
    var foto: String = "N/A"
    var body: String = "N/A"
    
    
    init(userid: Int? = nil, owner: Owner? = nil, vehicles: [Vehicle?]? = nil) {
      self.userid = userid
      self.owner = owner
      self.vehicles = vehicles
      
      if let name = owner?.name, let surname = owner?.surname {
        self.name = name + " " + surname
      }
      
      if let vehicles = vehicles {
        var vehicleBody: String = ""
        for v in vehicles {
          if let v = v {
            vehicleBody = vehicleBody +
            "make: \(v.make ?? "N/A"), model: \(v.model ?? "N/A"), year: \(v.year ?? "N/A"), color: \(v.color ?? "N/A"), vin: \(v.vin ?? "N/A")\n\n"
          }
        }
        if !vehicleBody.isEmpty { self.body = vehicleBody }
      }
    }
    
    func hash(into hasher: inout Hasher) {
      return hasher.combine(userid)
    }
    
    static func == (lhs: MainViewController.User, rhs: MainViewController.User) -> Bool {
      return lhs.userid == rhs.userid
    }
  }
  
  @objc func longPressed(sender: UILongPressGestureRecognizer) {
    if sender.state != .ended {
      return
    }
    
    let p = sender.location(in: self.collectionView)
    
    if let indexPath = self.collectionView.indexPathForItem(at: p) {
      var vc = storyboard?.instantiateViewController(withIdentifier: "map_vc") as! MapViewController
      vc.userId = indexPath.item + 1
      if let vehicles = users[indexPath.item].vehicles {
        for v in vehicles {
          vc.vehicles.append(UserVehicle(foto: v?.foto,
                                         name: v?.model,
                                         addres: "",
                                         color: v?.color)
          )
        }
      }
      
      let nc = UINavigationController(rootViewController: vc)
      present(nc, animated: false, completion: nil)
      
    } else {
      print("couldn't find index path")
    }
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

