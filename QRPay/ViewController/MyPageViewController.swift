//
//  MyPageViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 7/18/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit

class MyPageViewController: BaseViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "MY WALLET"
        if let walletAddress = (UIApplication.shared.delegate as! AppDelegate).userInfo.walletAddress {
            let walletDict = ["type":"wallet","address":walletAddress]
            if let jsonWallet = jsonEncode(dict: walletDict) {
                self.qrImageView.image = self.generateQRCode(from: jsonWallet)
            }
        } else {
            if let tabBarController = self.tabBarController as? TabBarController {
                tabBarController.getWalletAddress { (walletAddress) in
                    let walletDict = ["type":"wallet","address":walletAddress]
                    if let jsonWallet = self.jsonEncode(dict: walletDict) {
                        self.qrImageView.image = self.generateQRCode(from: jsonWallet)
                    }
                }
            }
        }
        // Do any additional setup after loading the view.
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
