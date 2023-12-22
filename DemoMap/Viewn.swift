//
//  Viewn.swift
//  DemoMap
//
//  Created by Gaurav Sara on 14/12/23.
//

import UIKit

class Viewn: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var iconText: UILabel!
    
    var customLabel: UILabel = {
       var label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        label.text = "Christmas Christmas Christmas Christmas"
        label.textColor = UIColor.orange
        
        return label
    }()
    
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
        
        let textAttributes = [NSAttributedString.Key.font: iconText.font]
        let textSize = (imageText as NSString?)?.size(withAttributes: textAttributes as [NSAttributedString.Key : Any])
            
        if let textSize = textSize {
            iconText.frame.size.width = textSize.width
        }
        
//      let newWidth: CGFloat = iconText.frame.size.width
        let newWidth: CGFloat = 200
        let newFrame = CGRect(x: 0, y: 0, width: newWidth, height: self.frame.size.height)
        self.frame = newFrame
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
