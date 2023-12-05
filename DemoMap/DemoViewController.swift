//
//  DemoViewController.swift
//  DemoMap
//
//  Created by Gaurav Sara on 29/11/23.
//

import UIKit

class DemoViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    var titleText : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleLabel.text = titleText
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
