//
//  BaseViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/16/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin

class BaseViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkLogin()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkLogin() {
        if let accessToken = AccessToken.current {
            print(accessToken)
        } else {
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginViewController") as! LoginViewController
            self.present(loginViewController, animated: false, completion: nil)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
