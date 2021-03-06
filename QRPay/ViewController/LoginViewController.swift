//
//  LoginViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 6/1/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin
import FBSDKShareKit
import Alamofire

class LoginViewController: BaseViewController {

    @IBOutlet var mainView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "login-bg1"))
    }

    @IBAction func login(_ sender: Any) {
        let loginManager = FBSDKLoginManager()

        loginManager.logIn(withReadPermissions: ["public_profile"], from: self) { (loginResult, error) in
            if let err = error {
                print(err)
            } else {
                if let currentUser = FBSDKProfile.current() {
                    self.didLogin(userID: currentUser.userID)
                } else {
                    FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
                        if let updatedUser = profile {
                            self.didLogin(userID: updatedUser.userID)
                        } else {
                            print("still cannot get")
                        }
                    })
                }
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    private func didLogin(userID: String) {
        // post request to server to get account's wallet or create new wallet if first time login
        Alamofire.request("\(Const.baseUrl)\(Const.signIn)", method: .post, parameters: ["id":userID], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
            print("request done")
            switch response.result {
            case .success:
                print("response: \(response)")
            case .failure(let error):
                print("error: \(error)")
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
