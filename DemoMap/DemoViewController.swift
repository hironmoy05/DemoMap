//
//  DemoViewController.swift
//  DemoMap
//
//  Created by Gaurav Sara on 29/11/23.
//

import UIKit
import GoogleMaps

class DemoViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    var titleText : String = ""
    var marker: GMSMarker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.numberOfLines = 0
        // Do any additional setup after loading the view.
        if let data = marker!.userData as? Person {
            titleLabel.text = "\(titleText) \n name: \(data.name) \n age: \(data.age) \n height: \(data.height)"
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
