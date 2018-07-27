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

enum ScanType: String {
    case wallet = "wallet"
    case card = "card"
    case product = "product"
}

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
    
    var isGetCoinBalanceDone = false
    var isGetAvatarDone = false
    
    // loading indicator
    @IBOutlet weak var loadingIndicatorView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // alert viewcontroller
    var alertVC = UIAlertController()
    var totalRequestCash: Double = 0
    
    // transHash
    var transHashes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.viewControllers?.forEach { let _ = $0.view }
        startIndicator()
        initCashBalance()
        notificationListener()
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
            showBalance()
        }
    }
    
    private func showBalance() {
        if let coinBalance = (UIApplication.shared.delegate as! AppDelegate).userInfo.coinBalance {
            stopIndicator()
            self.coinBalance = coinBalance
            self.coinBalanceLabel.text = "\(self.moneyFormat(amount: coinBalance, isShowingFractionDigit: true))"
        } else {
            if let tabBarController = self.tabBarController as? TabBarController {
                tabBarController.getCoinBalance { (amount) in
                    self.isGetCoinBalanceDone = true
                    if self.isGetAvatarDone {
                        self.stopIndicator()
                    }
                    self.coinBalanceLabel.text = "\(self.moneyFormat(amount: amount, isShowingFractionDigit: true))"
                }
            }
        }
    }
    
    private func initCashBalance() {
        self.cashBalance = Const.initialCashBalance
        cashBalanceLabel.text = "\(self.moneyFormat(amount: Const.initialCashBalance, isShowingFractionDigit: true))"
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
                            self.isGetAvatarDone = true
                            if self.isGetCoinBalanceDone {
                                self.stopIndicator()
                            }
                            self.avatarImageView.sd_setImage(with: URL(string:
                                profilePictureUrlString), completed: nil)
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
    
    // MARK: NOTIFICATION LISTENER
    private func notificationListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(cardScanned(_:)), name: .card, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transComplete(_:)), name: .trans, object: nil)
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
    
    @objc func transComplete(_ notification: Notification) {
        if let transDict = notification.object as? [String:Any] {
            if let coinAmount = transDict["ncoin"] as? Double, let coinBalance = (UIApplication.shared.delegate as! AppDelegate).userInfo.coinBalance {
                
                if let type = transDict["type"] as? String, type == "request" {
                    // update coin balance
                    (UIApplication.shared.delegate as! AppDelegate).userInfo.setCoinBalance(coinBalance: coinBalance + coinAmount)
                    self.coinBalance = coinBalance + coinAmount
                    self.coinBalanceLabel.text = "\(self.moneyFormat(amount: coinBalance + coinAmount, isShowingFractionDigit: true))"
                    
                    // update cash balance
                    self.cashBalance = self.cashBalance - coinAmount * 69.96
                    self.cashBalanceLabel.text = "\(self.moneyFormat(amount: self.cashBalance, isShowingFractionDigit: true))"
                    self.totalRequestCash = 0
                }
                
                if let type = transDict["type"] as? String, type == "wallet" || type == "product" {
                    // update coin balance
                    (UIApplication.shared.delegate as! AppDelegate).userInfo.setCoinBalance(coinBalance: coinBalance - coinAmount)
                    self.coinBalance = coinBalance - coinAmount
                    self.coinBalanceLabel.text = "\(self.moneyFormat(amount: coinBalance - coinAmount, isShowingFractionDigit: true))"
                }
            }
        }
    }
    
    // MARK: Loading Indicator
    
    private func startIndicator() {
        self.view.bringSubview(toFront: loadingIndicatorView)
        self.view.bringSubview(toFront: activityIndicatorView)
        loadingIndicatorView.isHidden = false
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    private func stopIndicator() {
        loadingIndicatorView.isHidden = true
        activityIndicatorView.isHidden = true
        activityIndicatorView.stopAnimating()
    }
    
    // MARK: - Navigation
    @IBAction func didSendCoinTapped(_ sender: Any) {
        navigateToQRScan(scanType: .wallet, coinBalance: self.coinBalance)
    }
    
    @IBAction func requestCoinDidTapped(_ sender: Any) {
        guard let userID = self.userID else {return}
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
            }
            cashAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                if self.totalRequestCash <= self.cashBalance {
                    self.requestCoin(userID: userID, amount: self.totalRequestCash / Const.coinValue, type: "request")
                }
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
            coinTextField.text = "\(Double(cash)! / Const.coinValue)"
            self.totalRequestCash = Double(cash)!
        } else {
            coinTextField.text = ""
        }
    }
    
    @objc func coinTextChange(_ sender: UITextField) {
        let moneyTextField = self.alertVC.textFields![0]
        if let coin = sender.text, !coin.isEmpty {
            moneyTextField.text = "\(Double(coin)! * Const.coinValue)"
            self.totalRequestCash = Double(coin)! * Const.coinValue
        } else {
            moneyTextField.text = ""
        }
    }
    
    private func requestCoin(userID: String, amount: Double, type: String) {
        
        let params: [String: Any] = ["id": userID, "ncoin": amount, "type": type]
        if let jsonParams = self.jsonEncode(dict: params) {
            print("params: \(jsonParams)")
            self.manager.defaultSocket.on(clientEvent: .connect) {_, _ in
                print("socket connected")
            }
            
            self.manager.defaultSocket.on("transcomplete") {data, _ in
                print("OKOKOK \(data)")
                if let transHash = self.getTransHash(data: data) {
                    if !self.checkDuplicateTransHash(transHash: transHash) {
                        self.transHashes.append(transHash)
                        NotificationCenter.default.post(name: .trans, object: ["ncoin":amount, "type": type])
                        NotificationCenter.default.post(name: .noti, object: data[0])
                    }
                }
            }
            
            if self.manager.defaultSocket.status == .connected {
                self.manager.defaultSocket.emit("sendtrans", params)
            } else {
                self.manager.defaultSocket.on("sendtransios") {data, _ in
                    print("sendtransresponse \(data)")
                    
                    self.manager.defaultSocket.emit("sendtrans", params)
                }
                self.manager.defaultSocket.connect()
            }
        }
    }
                
    private func getTransHash(data: [Any]) -> String? {
        if let dataObj = data[0] as? [String:Any] {
            if let transHash = dataObj["transHash"] as? String {
                return transHash
            }
            return nil
        } else {
            return nil
        }
    }
    
    private func checkDuplicateTransHash(transHash: String) -> Bool {
        if self.transHashes.count > 0 {
            for hash in self.transHashes {
                if hash == transHash {
                    return true
                }
            }
            return false
        } else {
            return false
        }
    }
    
    @IBAction func getMoneyDidTapped(_ sender: Any) {
        navigateToQRScan(scanType: .card, coinBalance: 0)
    }
    
    @IBAction func shoppingDidTapped(_ sender: Any) {
        navigateToQRScan(scanType: .product, coinBalance: self.coinBalance)
    }
    
    @IBAction func transHistoryDidTapped(_ sender: Any) {
        if let userID = userID {
            let transHistoryVC = self.storyboard?.instantiateViewController(withIdentifier: "transHistoryVC") as! TransactionHistoryViewController
            transHistoryVC.userID = userID
            self.navigationController?.pushViewController(transHistoryVC, animated: true)
        }
    }
    
    private func navigateToQRScan(scanType: ScanType, coinBalance: Double? = nil) {
        let qrVC = self.storyboard?.instantiateViewController(withIdentifier: "qrViewController") as! QRScanViewController
        qrVC.userID = self.userID
        qrVC.scanType = scanType
        if let coinBalance = coinBalance {
            qrVC.coinBalance = coinBalance
        }
        self.navigationController?.pushViewController(qrVC, animated: true)
    }
}
