//
//  NotificationTableViewCell.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/26/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    // MARK: IBOUTLET
    @IBOutlet weak var transTypeImageView: UIImageView!
    @IBOutlet weak var transTypeLabel: UILabel!
    @IBOutlet weak var transactionHashLabel: UILabel!
    @IBOutlet weak var transactionHashValueLabel: UILabel!
    @IBOutlet weak var sendReceiveImageView: UIImageView!
    @IBOutlet weak var transAmountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateUI(type: String, amount: Double, transHash: String) {
        print("type \(type)")
        transactionHashValueLabel.text = transHash
        transAmountLabel.text = "\(moneyFormat(amount: amount, isShowingFractionDigit: true))"
        
        if type == "wallet" {
            transTypeImageView.image = #imageLiteral(resourceName: "coin-wallet")
            transTypeLabel.text = "SEND COIN"
            sendReceiveImageView.image = #imageLiteral(resourceName: "send-coin")
            transAmountLabel.textColor = UIColor(red: 1, green: 0, blue: 10/255, alpha: 1.0)
        } else if type == "product" {
            transTypeLabel.text = "SHOPPING"
            transTypeImageView.image = #imageLiteral(resourceName: "shop")
            sendReceiveImageView.image = #imageLiteral(resourceName: "send-coin")
            transAmountLabel.textColor = UIColor(red: 1, green: 0, blue: 10/255, alpha: 1.0)
        } else if type == "request" {
            transTypeLabel.text = "REQUEST COIN"
            transTypeImageView.image = #imageLiteral(resourceName: "card")
            sendReceiveImageView.image = #imageLiteral(resourceName: "receive-coin")
            transAmountLabel.textColor = UIColor(red: 94/255, green: 1, blue: 0, alpha: 1.0)
        } else {
            transTypeLabel.text = "RECEIVE COIN"
            transTypeImageView.image = #imageLiteral(resourceName: "receive-money")
            sendReceiveImageView.image = #imageLiteral(resourceName: "receive-coin")
            transAmountLabel.textColor = UIColor(red: 94/255, green: 1, blue: 0, alpha: 1.0)
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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

}
