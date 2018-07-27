//
//  TabBarController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/24/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin
import Alamofire
import SocketIO

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    var notiCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUserInfo()
        checkLogin { (status) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkLogin(completion: @escaping(_ status: Bool) -> Void) {
        if let _ = AccessToken.current {
            completion(true)
        } else {
            completion(false)
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginViewController") as! LoginViewController
            self.present(loginViewController, animated: false, completion: nil)
        }
    }
    
    private func getUserInfo() {
        if let currentUser = FBSDKProfile.current() {
            (UIApplication.shared.delegate as! AppDelegate).userInfo.setUserID(userID: currentUser.userID)
            getWalletAddress { (walletAddress) in
                (UIApplication.shared.delegate as! AppDelegate).userInfo.setWalletAddress(walletAddress: walletAddress)
            }
            getCoinBalance { (amount) in
                (UIApplication.shared.delegate as! AppDelegate).userInfo.setCoinBalance(coinBalance: amount)
            }
        } else {
            FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
                if let updatedUser = profile {
                    (UIApplication.shared.delegate as! AppDelegate).userInfo.setUserID(userID: updatedUser.userID)
                    self.getWalletAddress { (walletAddress) in
                        (UIApplication.shared.delegate as! AppDelegate).userInfo.setWalletAddress(walletAddress: walletAddress)
                    }
                    self.getCoinBalance { (amount) in
                        (UIApplication.shared.delegate as! AppDelegate).userInfo.setCoinBalance(coinBalance: amount)
                    }
                } else {
                    print("still cannot get")
                }
            })
        }
    }
    
    // MARK: GET COIN & WALLET
    func getWalletAddress(completion: @escaping(_ balance: String) -> Void) {
        // get wallet address
        if let userID = (UIApplication.shared.delegate as! AppDelegate).userInfo.userID {
            Alamofire.request("\(Const.baseUrl)\(Const.wallet)", method: .post, parameters: ["id":userID], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
                print("WALLET request done")
                switch response.result {
                case .success:
                    if let walletObject = response.result.value as? [String:Any] {
                        if let walletAddress = walletObject["wallet"] as? String {
                            (UIApplication.shared.delegate as! AppDelegate).userInfo.setWalletAddress(walletAddress: walletAddress)
                            completion(walletAddress)
                        }
                    }
                case .failure(let error):
                    print("WALLET error: \(error)")
                }
            })
        }
    }
    
    func getCoinBalance(completion: @escaping(_ balance: Double) -> Void) {
        // get coin balance
        if let userID = (UIApplication.shared.delegate as! AppDelegate).userInfo.userID {
            print("\(Const.baseUrl)\(Const.balance)")
            Alamofire.request("\(Const.baseUrl)\(Const.balance)", method: .post, parameters: ["id":userID], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
                print("BALANCE request done")
                switch response.result {
                case .success:
                    print("balance response: \(response)")
                    if let responseObject = response.result.value as? [String:Any] {
                        if let coinBalance = responseObject["balance"] as? String {
                            (UIApplication.shared.delegate as! AppDelegate).userInfo.setCoinBalance(coinBalance: Double(coinBalance)!)
                            completion(Double(coinBalance)!)
                        }
                    }
                case .failure(let error):
                    print("BALANCE error: \(error)")
                }
            })
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
