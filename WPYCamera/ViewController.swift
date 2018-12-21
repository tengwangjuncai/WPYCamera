//
//  ViewController.swift
//  WPYCamera
//
//  Created by 王鹏宇 on 12/19/18.
//  Copyright © 2018 王鹏宇. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func goSwiftCamera(_ sender: UIButton) {
         self.present(Camera(), animated: true, completion: nil)
    }
    
    
    @IBAction func goOCCamera(_ sender: UIButton) {
        
        self.present(MyCamera(), animated: true, completion: nil)
    }
    
}

