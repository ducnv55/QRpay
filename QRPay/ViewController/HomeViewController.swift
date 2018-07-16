//
//  HomeViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/16/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin
import SDWebImage

class HomeViewController: BaseViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var addMoneyView: UIView!
    @IBOutlet weak var shoppingView: UIView!
    @IBOutlet weak var sendCoinView: UIView!
    @IBOutlet weak var getCoinView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _ = AccessToken.current {
            FBSDKProfile.enableUpdates(onAccessTokenChange: true)
            setupUI()
            getFacebookUserInfo()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFacebookUserInfo() {
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name, picture.type(large)"], tokenString: FBSDKAccessToken.current().tokenString, version: nil, httpMethod: "GET")
        request?.start(completionHandler: { (connection, result, error) in
            if let _ = error {
                print(error?.localizedDescription ?? "error")
            } else {
                if let res = result as? [String: Any] {
                    let profilePicture = res["picture"] as? [String:Any]
                    if let profilePictureData = profilePicture!["data"] as? [String:Any] {
                        if let profilePictureUrlString = profilePictureData["url"] as? String {
                            self.avatarImageView.sd_setImage(with: URL(string: profilePictureUrlString), completed: nil)
                        }
                    }
                }
            }
        })
    }
    
    func setupUI() {
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        addMoneyView.layer.cornerRadius = addMoneyView.frame.width / 2
        shoppingView.layer.cornerRadius = shoppingView.frame.width / 2
        sendCoinView.layer.cornerRadius = sendCoinView.frame.width / 2
        getCoinView.layer.cornerRadius = getCoinView.frame.width / 2
    }

    @IBAction func logout(_ sender: Any) {
        FBSDKLoginManager().logOut()
        let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginViewController") as! LoginViewController
        self.present(loginViewController, animated: false, completion: nil)
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
