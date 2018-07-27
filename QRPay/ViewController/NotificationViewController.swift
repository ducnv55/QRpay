//
//  NotificationViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/24/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit

struct NotificationItem {
    let type: String
    let ncoin: Double
    let transHash: String
}

class NotificationViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var notifications: [NotificationItem] = []
    
    // MARK: IBOUTLET
    @IBOutlet weak var totalCoinSentLabel: UILabel!
    @IBOutlet weak var totalCoinReceiveLabel: UILabel!
    @IBOutlet weak var notiTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notiTableView.rowHeight = UITableViewAutomaticDimension
        notiTableView.estimatedRowHeight = 100
        
        updateBalanceChanges()
        self.notificationListerner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.notiTableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        notifications.removeAll()
        self.tabBarController?.tabBar.items![1].badgeValue = nil
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.notiCount = 0
        }
        updateBalanceChanges()
    }
    
    private func updateBalanceChanges() {
        var totalSendAmount: Double = 0
        var totalReceiveAmount: Double = 0
        for notiItem in notifications {
            if notiItem.type == "wallet" || notiItem.type == "product" {
                totalSendAmount = totalSendAmount + notiItem.ncoin
            } else {
                totalReceiveAmount = totalReceiveAmount + notiItem.ncoin
            }
        }
        
        totalCoinSentLabel.text = "\(moneyFormat(amount: totalSendAmount, isShowingFractionDigit: true))"
        totalCoinReceiveLabel.text = "\(moneyFormat(amount: totalReceiveAmount, isShowingFractionDigit: true))"
        
        self.notiTableView.reloadData()
    }
    
    private func notificationListerner() {
        NotificationCenter.default.addObserver(self, selector: #selector(notiReceived(_:)), name: .noti, object: nil)
    }
    
    @objc func notiReceived(_ notification: Notification) {
        if let notiObject = notification.object as? [String:Any] {
            if let ncoin = notiObject["ncoin"] as? String, var type = notiObject["type"] as? String, let tranHash = notiObject["transHash"] as? String {
                let doubleNcoin = (ncoin as NSString).doubleValue
                if let _ = notiObject["uidTo"] as? String {
                    type = "receiveCoin"
                }
                let notiItem = NotificationItem(type: type, ncoin: doubleNcoin, transHash: tranHash)
                if !isDuplicateTransHashes(transHash: notiItem.transHash) {
                    notifications.append(NotificationItem(type: type, ncoin: doubleNcoin, transHash: tranHash))
                    updateBalanceChanges()
                    if let tabBarController = self.tabBarController as? TabBarController {
                        tabBarController.notiCount = self.notifications.count
                        self.tabBarController?.tabBar.items![1].badgeValue = "\(tabBarController.notiCount)"
                    }
                    
                }
            }
        }
    }
    
    private func isDuplicateTransHashes(transHash: String) -> Bool {
        if self.notifications.count > 0 {
            for notiItem in self.notifications {
                if notiItem.transHash == transHash {
                    return true
                }
            }
            return false
        } else {
            return false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notiCell", for: indexPath) as! NotificationTableViewCell
        let data = notifications[indexPath.row]
        cell.updateUI(type: data.type, amount: data.ncoin, transHash: data.transHash)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
   
}
