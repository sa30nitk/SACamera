//
//  SACameraViewController.swift
//  Pods
//
//  Created by SATEESH on 07/09/16.
//
//

import UIKit

public class SACameraViewController: UIViewController {

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    public static func getCameraViewController() -> SACameraViewController {
        

        let storyboard = UIStoryboard(name: "SACamera", bundle: Bundle.currentBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "SACameraViewController") as! SACameraViewController
        return vc
    }
}



internal extension Bundle {
    static func currentBundle() -> Bundle? { return SACameraBundleHelper.getBundle() }
}


private class SACameraBundleHelper : NSObject {
    static func getBundle() -> Bundle? {
        let podBundle = Bundle(for: SACameraBundleHelper.self)
        guard let bundleURL = podBundle.url(forResource: "SACamera", withExtension: "bundle") else { return nil }
        guard let bundle = Bundle(url: bundleURL) else { return nil }
        return bundle
    }
    
}

