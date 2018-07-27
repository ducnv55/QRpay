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
import Alamofire
import SocketIO

class BaseViewController: UIViewController {
    
    var uID: String?
    let manager = SocketManager(socketURL: URL(string: "\(Const.baseUrl)\(Const.transfer)")!, config: [.log(true), .compress])
    
    // transHash
    var baseTransHashes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSocket()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.isKind(of: LoginViewController.self) {
            checkLogin { (status) in
                print("LOGIN STATUS: \(status)")
            }
        }
        self.navigationController?.navigationBar.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initSocket() {
        
        if let currentUser = FBSDKProfile.current() {
            self.uID = currentUser.userID
        } else {
            FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
                if let updatedUser = profile {
                    self.uID = updatedUser.userID
                } else {
                    print("still cannot get")
                }
            })
        }
        
        manager.defaultSocket.on(clientEvent: .connect) {_, _ in
            print("socket connected")
        }
        
        manager.defaultSocket.on("transwallet") {data, _ in
            print("OKOKOK \(data)")
            if let obj = data[0] as? [String:Any] {
                if let uID = obj["uidTo"] as? String,
                    let userID = self.uID, uID == userID,
                    let transHash = obj["transHash"] as? String,
                    let ncoin = obj["ncoin"] as? String,
                    let type = obj["type"] as? String {
                    
                    if !self.checkDuplicateTransHash(transHash: transHash) {
                        self.baseTransHashes.append(transHash)
                        
                        let notiObject = ["type": type, "ncoin": ncoin, "transHash": transHash, "uidTo": uID]
                        
                        NotificationCenter.default.post(name: .noti, object: notiObject)
                    }
                }
            }
        }
        
        self.manager.defaultSocket.connect()
    }
    
    private func checkDuplicateTransHash(transHash: String) -> Bool {
        if self.baseTransHashes.count > 0 {
            for hash in self.baseTransHashes {
                if hash == transHash {
                    return true
                }
            }
            return false
        } else {
            return false
        }
    }
    
    func moneyFormat(amount: Double, isShowingFractionDigit: Bool = false) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        if isShowingFractionDigit {
            numberFormatter.decimalSeparator = "."
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 2
        }
        return numberFormatter.string(from: amount as NSNumber)!
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
    
    func jsonEncode(dict: [String: Any]) -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
            let jsonString = String(data: jsonData,
                                     encoding: String.Encoding.ascii) {
            return jsonString
        } else {
            return nil
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
