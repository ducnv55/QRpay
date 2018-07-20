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
import SwiftSocket

class QRScanViewController: BaseViewController {
    
    var userID: String?
    var captureSession = AVCaptureSession()
    
    var isAllowScanning = true
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                if let destinationWalletAddress = object["address"] as? String, let _ = self.userID {
                    // send POST request
                    Alamofire.request("http://192.168.0.253:8000/sendtrans", method: .post, parameters: ["id":self.userID!, "txto": destinationWalletAddress, "ncoin": 100], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
                        print("request done")
                        switch response.result {
                        case .success:
                            print("response: \(response)")
                            let alertPrompt = UIAlertController(title: "Response", message: "\(response.description)", preferredStyle: .actionSheet)
                            let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                                // transfer coin successfully
                                self.isAllowScanning = true
                                self.navigationController?.popViewController(animated: true)
                            })
                            alertPrompt.addAction(confirmAction)
                            
                            self.present(alertPrompt, animated: true, completion: nil)
                        case .failure(let error):
                            print("error: \(error)")
                        }
                    })
                }
            case "card":
                if let cardValue = object["value"] as? String, let _ = self.userID {
                    // create notification that card is scanned
                    NotificationCenter.default.post(name: .card, object: ["value": Double(cardValue)!])
                }
            case "product":
                if let productName = object["name"] as? String, let price = object["price"] as? Double, let _ = self.userID {
                    
                    let alertPrompt = UIAlertController(title: "PRODUCT DETECTED!", message: "Product: \(productName) \n Price: $\(price) \n Coin: \(self.moneyFormat(amount: price / 69.96, isShowingFractionDigit: true))", preferredStyle: .actionSheet)
                    let confirmAction = UIAlertAction(title: "CHECKOUT", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                        // prompt again to make sure user want to buy
                        let alertPrompt = UIAlertController(title: "Are you sure you want to buy this product?", message: "\(productName) \n Price: $\(price) \n Coin: \(self.moneyFormat(amount: price / 69.96, isShowingFractionDigit: true))", preferredStyle: .alert)
                        let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                            // post request to transfer coin
                            
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
            default:
                print("default")
            }
        }
        print(object)
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
}
