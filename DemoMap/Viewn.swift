//
//  Viewn.swift
//  DemoMap
//
//  Created by Gaurav Sara on 14/12/23.
//

import Foundation
import UIKit

class Viewn: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var iconText: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI(image: UIImage, imageText: String? = "") {
        iconImage.image = image
        iconText.text = imageText
        iconText.textAlignment = .center
    }

    class func loadView() -> Viewn {
        let nib = UINib(nibName: "Viewn", bundle: nil)
        if let value =  nib.instantiate(withOwner: self, options: nil)[0] as? Viewn {
          
            return value
        } else {
            return Viewn(frame: CGRect.zero)
        }
    }
    
}
