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
import Alamofire

class HomeViewController: BaseViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var addMoneyView: UIView!
    @IBOutlet weak var shoppingView: UIView!
    @IBOutlet weak var sendCoinView: UIView!
    @IBOutlet weak var getCoinView: UIView!
    
    @IBOutlet weak var coinBalanceLabel: UILabel!
    @IBOutlet weak var cashBalanceLabel: UILabel!
    
    var userID: String?
    var walletAddress: String?
    var coinBalance: Double?
    var cashBalance: Double = 0
    
    var isAllowGetUserInfo = true
    
    // alert viewcontroller
    var alertVC = UIAlertController()
    var totalRequestCash: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCashBalance()
        notificationListener()
        
        
        let imageViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarDidTapped))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(imageViewTapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let _ = AccessToken.current {
            FBSDKProfile.enableUpdates(onAccessTokenChange: true)
            setupUI()
            if isAllowGetUserInfo {
                getFacebookUserInfo()
                isAllowGetUserInfo = false
            }
            self.getWalletAddress { (walletAdderss) in
                self.walletAddress = walletAdderss
            }
            self.getCoinBalance { (amount) in
                self.coinBalance = amount
                self.coinBalanceLabel.text = "\(self.moneyFormat(amount: amount, isShowingFractionDigit: true))"
            }
        }
    }
    
    private func initCashBalance() {
        self.cashBalance = Const.initialCashBalance
        cashBalanceLabel.text = "\(self.moneyFormat(amount: Const.initialCashBalance))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFacebookUserInfo() {
        // store user id
        if let currentUser = FBSDKProfile.current() {
            self.userID = currentUser.userID
        } else {
            FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
                if let updatedUser = profile {
                    self.userID = updatedUser.userID
                } else {
                    print("still cannot get")
                }
            })
        }
        
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
        self.navigationController?.navigationBar.isHidden = true
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
    
    // out
    @IBAction func didRequestCoinTapped(_ sender: Any) {
    }
    
    
    // MARK: GET COIN & WALLET
    func getWalletAddress(completion: @escaping(_ walletAddress: String) -> Void) {
        // get wallet address
        if let userID = self.userID {
            Alamofire.request("\(Const.baseUrl)\(Const.wallet)", method: .post, parameters: ["id":userID], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
                print("WALLET request done")
                switch response.result {
                case .success:
                    if let walletObject = response.result.value as? [String:Any] {
                        if let walletAddress = walletObject["wallet"] as? String {
                            print("WALLET address: \(walletAddress)")
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
        if let userID = self.userID {
            print("\(Const.baseUrl)\(Const.balance)")
            Alamofire.request("\(Const.baseUrl)\(Const.balance)", method: .post, parameters: ["id":userID], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
                print("BALANCE request done")
                switch response.result {
                case .success:
                    print("balance response: \(response)")
                    if let responseObject = response.result.value as? [String:Any] {
                        if let coinBalance = responseObject["balance"] as? String {
                            completion(Double(coinBalance)!)
                        }
                    }
                case .failure(let error):
                    print("BALANCE error: \(error)")
                }
            })
        }
    }
    
    // MARK: NOTIFICATION LISTENER
    private func notificationListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(cardScanned(_:)), name: .card, object: nil)
    }
    
    @objc func cardScanned(_ notification: Notification) {
        if let cardDict = notification.object as? [String:Double] {
            if let cardValue = cardDict["value"] {
                self.cashBalance = self.cashBalance + cardValue
                self.cashBalanceLabel.text = "\(self.moneyFormat(amount: self.cashBalance))"
                
                // alert viewcontroller to go back to previous screen
                let alert = UIAlertController(title: "CARD DETECTED", message: "You received $\(cardValue)!", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.navigationController?.popViewController(animated: false)
                    }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Navigation
    @IBAction func didSendCoinTapped(_ sender: Any) {
        navigateToQRScan()
    }
    
    @IBAction func requestCoinDidTapped(_ sender: Any) {
        let alert = UIAlertController(title: "BUY COIN", message: "Enter $ or Coin you want to buy", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.placeholder = "$ amount you want"
            textField.addTarget(self, action: #selector(self.moneyTextChange(_:)), for: .editingChanged)
        }
        
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.placeholder = "Coin amount you want"
            textField.addTarget(self, action: #selector(self.coinTextChange(_:)), for: .editingChanged)
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            let cashAlert = UIAlertController(title: "YOUR COIN IS COMING...", message: "This transaction is pending.\nCoin will be transfer to your account automatically.", preferredStyle: .alert)
            if self.totalRequestCash > self.cashBalance {
                cashAlert.title = "WARNING!!!"
                cashAlert.message = "Your cash balance is not enough."
            } else {
                self.cashBalance = self.cashBalance - self.totalRequestCash
                self.cashBalanceLabel.text = "\(self.moneyFormat(amount: self.cashBalance))"
            }
            cashAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
            }))
            
            self.present(cashAlert, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("Cancel")
        }))
        
        self.alertVC = alert
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @objc func moneyTextChange(_ sender: UITextField) {
        let coinTextField = self.alertVC.textFields![1]
        if let cash = sender.text, !cash.isEmpty {
            coinTextField.text = "\(Double(cash)! / 69.96)"
            self.totalRequestCash = Double(cash)!
        } else {
            coinTextField.text = ""
        }
    }
    
    @objc func coinTextChange(_ sender: UITextField) {
        let moneyTextField = self.alertVC.textFields![0]
        if let coin = sender.text, !coin.isEmpty {
            moneyTextField.text = "\(Double(coin)! * 69.96)"
            self.totalRequestCash = Double(coin)! * 69.96
        } else {
            moneyTextField.text = ""
        }
    }
    
    @IBAction func getMoneyDidTapped(_ sender: Any) {
        navigateToQRScan()
    }
    
    @IBAction func shoppingDidTapped(_ sender: Any) {
        navigateToQRScan()
    }
    
    private func navigateToQRScan() {
        let qrVC = self.storyboard?.instantiateViewController(withIdentifier: "qrViewController") as! QRScanViewController
        qrVC.userID = self.userID
        self.navigationController?.pushViewController(qrVC, animated: true)
    }
    
    // Mypage: show current user's qr code's wallet
    @objc func avatarDidTapped() {
        if let myPageVC = self.storyboard?.instantiateViewController(withIdentifier: "mypageViewController") as? MyPageViewController {
            myPageVC.walletAddress = self.walletAddress
            self.navigationController?.pushViewController(myPageVC, animated: true)
        }
    }

}
