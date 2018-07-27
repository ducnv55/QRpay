//
//  QRScanViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 5/24/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class QRScanViewController: BaseViewController {
    
    var scanType: ScanType?
    var userID: String?
    var totalRequestCoin: Double = 0
    var coinBalance: Double?
    var alertVC = UIAlertController()
    
    // loading indicator
    @IBOutlet weak var loadingIndicatorView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // transHash
    var transHashes: [String] = []
    
    // QR properties
    var captureSession = AVCaptureSession()
    
    var isAllowScanning = true
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scanType = self.scanType {
            self.navigationItem.title = scanType.rawValue
        }
        qrScanning()
    }
    
    func qrScanning() {
        // Do any additional setup after loading the view.
        
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper methods
    func itemInfo(json: String) {
        
        if presentedViewController != nil {
            return
        }
        
        let jsonData = json.data(using: .utf8)
        
        guard let object = try? JSONSerialization.jsonObject(with: jsonData!, options: []) as! [String: Any] else {
            return
        }
        
        if let dataType = object["type"] as? String {
            switch dataType {
            case "wallet":
                if let scanType = self.scanType, dataType == scanType.rawValue {
                    self.walletScan(object)
                }
            case "card":
                if let scanType = scanType, dataType == scanType.rawValue {
                    self.cardScan(object)
                }
            case "product":
                if let scanType = scanType, dataType == scanType.rawValue {
                    self.productScan(object)
                }
            default:
                print("default")
            }
        }
        print(object)
    }
    
    // MARK: QR SCAN TYPES
    private func walletScan(_ object: [String: Any]) {
        if let destinationWalletAddress = object["address"] as? String, let userID = self.userID {
            // send POST request
            let alertPrompt = UIAlertController(title: "WALLET DETECTED!", message: "Wallet address: \(destinationWalletAddress)", preferredStyle: .alert)
            alertPrompt.addTextField { (textField) in
                textField.keyboardType = .numberPad
                textField.placeholder = "$ amount you want"
                textField.addTarget(self, action: #selector(self.moneyTextChange(_:)), for: .editingChanged)
            }
            
            alertPrompt.addTextField { (textField) in
                textField.keyboardType = .numberPad
                textField.placeholder = "Coin amount you want"
                textField.addTarget(self, action: #selector(self.coinTextChange(_:)), for: .editingChanged)
            }
            
            let confirmAction = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                let cashAlert = UIAlertController(title: "TRANSACTION IS PENDING...", message: "This transaction is mining.\nYour coin will be transfered automatically.", preferredStyle: .alert)
                
                if let coinBalance = self.coinBalance, self.totalRequestCoin > coinBalance {
                    cashAlert.title = "WARNING!!!"
                    cashAlert.message = "Your coin is not enough."
                } else {
                    // send coin using socket ui
                    let moneyTextField = self.alertVC.textFields![1].text
                    if let cashAmount = Double(moneyTextField!) {
                        self.alertVC = cashAlert
                        self.sendCoin(userID: userID, destinationWalletAddress: destinationWalletAddress, amount: cashAmount, type: object["type"] as! String)
                    }
                }
                cashAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    self.navigationController?.popViewController(animated: true)
                }))
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            })
            
            alertPrompt.addAction(confirmAction)
            alertPrompt.addAction(cancelAction)
            
            self.alertVC = alertPrompt
            
            present(self.alertVC, animated: true, completion: nil)
        }
    }
    
    @objc func moneyTextChange(_ sender: UITextField) {
        let coinTextField = self.alertVC.textFields![1]
        if let cash = sender.text, !cash.isEmpty {
            coinTextField.text = "\(Double(cash)! / Const.coinValue)"
            self.totalRequestCoin = Double(cash)! / Const.coinValue
        } else {
            coinTextField.text = ""
        }
    }
    
    @objc func coinTextChange(_ sender: UITextField) {
        let moneyTextField = self.alertVC.textFields![0]
        if let coin = sender.text, !coin.isEmpty {
            moneyTextField.text = "\(Double(coin)! * Const.coinValue)"
            self.totalRequestCoin = Double(coin)!
        } else {
            moneyTextField.text = ""
        }
    }
    
    private func sendCoin(userID: String, destinationWalletAddress: String? = nil, amount: Double, type: String) {
        
        if let walletAddress = destinationWalletAddress {
            // send coin to specific wallet address
            let params: [String: Any] = ["id": userID, "txto": walletAddress, "ncoin": amount, "type": type]
                self.sendTrans(params: params)
        }
    }
    
    private func cardScan(_ object: [String: Any]) {
        if let cardValue = object["value"] as? String, let _ = self.userID {
            // create notification that card is scanned
            NotificationCenter.default.post(name: .card, object: ["value": Double(cardValue)!])
        }
    }
    
    private func productScan(_ object: [String: Any]) {
        
        guard let userID = self.userID else {return}
        
        if let productName = object["name"] as? String, let price = object["price"] as? Double, let destinationWalletAddr = object["txto"] as? String {
            
            self.totalRequestCoin = price / Const.coinValue
            
            let alertPrompt = UIAlertController(title: "PRODUCT DETECTED!", message: "Product: \(productName) \n Price: $\(price) \n Coin: \(self.moneyFormat(amount: price / Const.coinValue, isShowingFractionDigit: true))", preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: "CHECKOUT", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                // prompt again to make sure user want to buy
                let alertPrompt = UIAlertController(title: "Are you sure you want to buy this product?", message: "\(productName) \n Price: $\(price) \n Coin: \(self.moneyFormat(amount: price / Const.coinValue, isShowingFractionDigit: true))", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                    self.startIndicator()
                    // post request to transfer coin
                    let cashAlert = UIAlertController(title: "TRANSACTION IS PENDING...", message: "This transaction is mining.\nYour coin will be transfered automatically.", preferredStyle: .alert)
                    
                    if let coinBalance = self.coinBalance, self.totalRequestCoin > coinBalance {
                        cashAlert.title = "WARNING!!!"
                        cashAlert.message = "Your coin is not enough."
                    } else {
                        // send coin using socket ui
                        self.alertVC = cashAlert
                        self.sendCoin(userID: userID, destinationWalletAddress: destinationWalletAddr, amount: self.totalRequestCoin, type: object["type"] as! String)
                    }
                    cashAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        self.navigationController?.popViewController(animated: true)
                    }))
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
                    self.navigationController?.popViewController(animated: true)
                })
                
                alertPrompt.addAction(cancelAction)
                alertPrompt.addAction(confirmAction)
                
                self.present(alertPrompt, animated: true, completion: nil)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            
            alertPrompt.addAction(confirmAction)
            alertPrompt.addAction(cancelAction)
            
            present(alertPrompt, animated: true, completion: nil)
        }
    }
    
    // MARK: Send Transaction
    private func sendTrans(params: [String:Any]) {
        
        guard let jsonParams = jsonEncode(dict: params) else { return }
        
        print("send params: \(params)")
        self.manager.defaultSocket.on(clientEvent: .connect) {_, _ in
            print("socket connected")
        }
        
        self.manager.defaultSocket.on("transcomplete") {data, _ in
            print("OKOKOK \(data)")
            if let transHash = self.getTransHash(data: data) {
                if !self.checkDuplicateTransHash(transHash: transHash) {
                    self.transHashes.append(transHash)
                    self.transCompleted(params: params)
                    self.pushNoti(data: data[0])
                }
            }
        }
        
        if self.manager.defaultSocket.status == .connected {
            self.stopIndicator()
            self.present(self.alertVC, animated: true, completion: nil)
            self.manager.defaultSocket.emit("sendtrans", jsonParams)
        } else {
            self.manager.defaultSocket.on("sendtransios") {data, _ in
                print("sendtransresponse \(data)")
                self.stopIndicator()
                self.present(self.alertVC, animated: true, completion: nil)
                self.manager.defaultSocket.emit("sendtrans", jsonParams)
            }
            self.manager.defaultSocket.connect()
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
    
    private func transCompleted(params: [String:Any]) {
        NotificationCenter.default.post(name: .trans, object: params)
    }
    
    private func pushNoti(data: Any) {
        NotificationCenter.default.post(name: .noti, object: data)
    }
    
    private func startIndicator() {
        loadingIndicatorView.isHidden = false
        self.view.bringSubview(toFront: activityIndicatorView)
        self.view.bringSubview(toFront: loadingIndicatorView)
        activityIndicatorView.startAnimating()
    }
    
    private func stopIndicator() {
        activityIndicatorView.stopAnimating()
        loadingIndicatorView.isHidden = true
        activityIndicatorView.isHidden = true
    }
    
}

extension QRScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil, isAllowScanning {
                isAllowScanning = false
                itemInfo(json: metadataObj.stringValue!)
            }
        }
    }
    
}

extension Notification.Name {
    static let card = Notification.Name("card")
    static let trans = Notification.Name("trans")
    static let noti = Notification.Name("noti")
}
