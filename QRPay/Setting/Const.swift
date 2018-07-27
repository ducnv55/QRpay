//
//  Const.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/16/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import Foundation

class Const {
    static let baseUrl: String = "http://192.168.0.222:8000/"
    static let signIn: String = "signin"
    static let balance: String = "balance"
    static let wallet: String = "getwallet"
    static let transfer: String = "sendtrans"
    static let transHistory: String = "listtransactions"
    
    // balance
    static let initialCashBalance: Double = 0
    
    // coin value
    static let coinValue: Double = 69.96
}
