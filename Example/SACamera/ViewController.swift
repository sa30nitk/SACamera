//
//  ViewController.swift
//  SACamera
//
//  Created by SATEESH on 09/06/2016.
//  Copyright (c) 2016 SATEESH. All rights reserved.
//

import UIKit
import SACamera

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonTapped(_ sender: AnyObject) {
        
        
        let vc = SACameraViewController.getCameraViewController()
        self.present(vc, animated: true, completion: nil)
        
    }
}

