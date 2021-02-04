//
//  LocationCarouselController.swift
//  MapDirectionsGooglePlaces
//
//  Created by Vikram Ho on 1/21/21.
//

import UIKit
import LBTATools
import MapKit

class LocationCell: LBTAListCell<MKMapItem>{
    
    override var item: MKMapItem!{
        didSet{
            label.text = item.name
            addressLabel.text = item.displayAddress()
        }
    }
    let label = UILabel(text: "Location", font: .boldSystemFont(ofSize: 16))
    
    let addressLabel = UILabel(text: "Address", numberOfLines: 0)
    
    override func setupViews() {
        backgroundColor = .white
        
        setupShadow(opacity: 0.8, radius: 5, offset: .zero, color: .black)
        layer.cornerRadius = 15
        
        stack(label, addressLabel).withMargins(.allSides(16))
    }
}

class LocationCarouselController: LBTAListController<LocationCell, MKMapItem> {
    
    weak var mainController: MainController?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       
        
        let annotations = mainController?.mapView.annotations
        annotations?.forEach({ (annotation) in
            guard let customAnnotation = annotation as? MainController.CustomMapItemAnnotation else { return }
            if customAnnotation.mapItem?.name == self.items[indexPath.item].name {
                mainController?.mapView.selectAnnotation(annotation, animated: true)
            }
        })
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = .clear
        
//        let placemark = MKPlacemark(coordinate: .init(latitude: 10, longitude: 55))
//        let dummyMapitem = MKMapItem(placemark: placemark)
//        dummyMapitem.name = "Dummy location"
//        self.items = [dummyMapitem]
    }
}


extension LocationCarouselController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 64, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}
