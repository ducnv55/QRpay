//
//  QRScanViewController.swift
//  QRPay
//
//  Created by Duc Nguyen Viet on 5/24/18.
//  Copyright © 2018 TMH Tech Lab. All rights reserved.
//

import UIKit
import AVFoundation
import FBSDKLoginKit
import FacebookCore
import FacebookLogin

class QRScanViewController: UIViewController {
    
    var captureSession = AVCaptureSession()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        qrScanning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.checkLogin()
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
            //            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
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
        
        // Move the message label and top bar to the front
//        view.bringSubview(toFront: messageLabel)
//        view.bringSubview(toFront: topView)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }
    
    func checkLogin() {
        if let accessToken = AccessToken.current {
            print(accessToken)
        } else {
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginViewController") as! LoginViewController
            self.present(loginViewController, animated: false, completion: nil)
        }
    }
    
//    @IBAction func logout(_ sender: Any) {
//        let loginManager = FBSDKLoginManager()
//        loginManager.logOut()
//        let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginViewController")
//        self.present(loginViewController!, animated: true, completion: nil)
//    }
    
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
        
        let productObject = try? JSONSerialization.jsonObject(with: jsonData!, options: []) as! [String: Any]
        let product = Product(name: productObject!["name"] as! String,
                                 price: productObject!["price"] as! Double,
                                 description: productObject?["description"] as? String)
        print(product)
        
        let alertPrompt = UIAlertController(title: "Product's information", message: "Product: \(product.name) \n Price: $\(product.price) \n BTC: 0.5143", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "CHECKOUT", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            // prompt again to make sure user want to buy
            let alertPrompt = UIAlertController(title: "Are you sure you want to buy this product?", message: "\(product.name) \n Price: $\(product.price) \n BTC: 0.5143", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                // post request to transfer coin
                
                
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil)
            
            alertPrompt.addAction(cancelAction)
            alertPrompt.addAction(confirmAction)
            
            self.present(alertPrompt, animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }
    
//    @IBAction func insertMoneyDidTapped(_ sender: Any) {
//        let alertPrompt = UIAlertController(title: "GET MORE COIN", message: "", preferredStyle: .alert)
//        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
//            if let field = alertPrompt.textFields?[0] {
//                // store your data
//                UserDefaults.standard.set(field.text, forKey: "userEmail")
//                UserDefaults.standard.synchronize()
//            } else {
//                // user did not fill field
//            }
//        }
//
//        alertPrompt.addTextField { (textfield) in
//            textfield.placeholder = "Number of coins"
//            textfield.keyboardType = .numberPad
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil)
//
//        alertPrompt.addAction(cancelAction)
//        alertPrompt.addAction(confirmAction)
//
//        present(alertPrompt, animated: true, completion: nil)
//    }
}




extension QRScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
//            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                itemInfo(json: metadataObj.stringValue!)
//                messageLabel.text = metadataObj.stringValue
            }
        }
    }
    
}
