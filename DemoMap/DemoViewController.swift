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
    var me: Person?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleLabel.text = titleText
        if let me {
            print(me.name, me.age, me.height)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
