//
//  TransactionHistoryViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/26/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import Alamofire

class TransactionHistoryViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var transHistoryTableView: UITableView!
    var userID: String!
    
    private var historyItems: [NotificationItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Transaction History"
        getTransactionHistory { (result) in
            for transaction in result {
                if let ncoin = transaction["value"] as? String, var type = transaction["type"] as? String, let tranHash = transaction["transhash"] as? String {
                    let doubleNcoin = (ncoin as NSString).doubleValue
                    if let _ = transaction["uidTo"] as? String {
                        type = "receiveCoin"
                    }
                    self.historyItems.append(NotificationItem(type: type, ncoin: doubleNcoin, transHash: tranHash))
                }
            }
            self.transHistoryTableView.reloadData()
        }
        
        transHistoryTableView.rowHeight = UITableViewAutomaticDimension
        transHistoryTableView.estimatedRowHeight = 100
    }
    
    private func getTransactionHistory(completion: @escaping(_ transactionItems: [[String:Any]]) -> Void) {
        
        let jsonParam = jsonEncode(dict: ["id" : userID])
        
        Alamofire.request("\(Const.baseUrl)\(Const.transHistory)", method: .post, parameters: ["id":jsonParam!], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
            print("request done")
            switch response.result {
            case .success:
                if let arrayResult = response.result.value as? [[String:Any]] {
                    completion(arrayResult)
                }
            case .failure(let error):
                print("error: \(error)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transHistoryCell", for: indexPath) as! TransactionHistoryTableViewCell
        let data = historyItems[indexPath.row]
        cell.updateUI(type: data.type, amount: data.ncoin, transHash: data.transHash)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }

}
