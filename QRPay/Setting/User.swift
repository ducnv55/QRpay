//
//  User.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/24/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import Foundation

struct User {
    var userID: String?
    var walletAddress: String?
    var coinBalance: Double?
}

extension User {
    public mutating func setUserID(userID: String) {
        self.userID = userID
    }
    
    public mutating func setWalletAddress(walletAddress: String) {
        self.walletAddress = walletAddress
    }
    
    public mutating func setCoinBalance(coinBalance: Double) {
        self.coinBalance = coinBalance
    }
}
