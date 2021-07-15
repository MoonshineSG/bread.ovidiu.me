import AVFoundation
import UIKit
import RNCryptor

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                DispatchQueue.main.async {
                    self.view.backgroundColor = UIColor.black
                    self.captureSession = AVCaptureSession()
                    
                    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
                    let videoInput: AVCaptureDeviceInput
                    
                    
                    do {
                        videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                    } catch {
                        return
                    }
                    
                    if (self.captureSession.canAddInput(videoInput)) {
                        self.captureSession.addInput(videoInput)
                    } else {
                        self.failed()
                        return
                    }
                    
                    let metadataOutput = AVCaptureMetadataOutput()
                    
                    if (self.captureSession.canAddOutput(metadataOutput)) {
                        self.captureSession.addOutput(metadataOutput)
                        
                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.qr]
                    } else {
                        self.failed()
                        return
                    }
                    
                    let scannerOverlayPreviewLayer = ScannerOverlayPreviewLayer(session: self.captureSession)
                    scannerOverlayPreviewLayer.frame = self.view.bounds
                    scannerOverlayPreviewLayer.maskSize = CGSize(width: 280, height: 280)
                    
                    scannerOverlayPreviewLayer.lineWidth = 2
                    scannerOverlayPreviewLayer.cornerLength = 140
                    scannerOverlayPreviewLayer.lineColor = .sourdough_green
                    scannerOverlayPreviewLayer.backgroundColor = UIColor.transparentBlack.cgColor
                    scannerOverlayPreviewLayer.videoGravity = .resizeAspectFill
                    self.view.layer.addSublayer(scannerOverlayPreviewLayer)
                    
                    metadataOutput.rectOfInterest = scannerOverlayPreviewLayer.rectOfInterest
                }
            } else {
                let ac = UIAlertController(title: "Scanning not supported", message: "Allow camera access.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
        }
        
        
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) )
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print(captureSession)
        if (captureSession?.isRunning == false) {
            print("ok")
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)            
        }
    }
    
    func found(code: String) {
        if code.hasPrefix("bread:") {
            self.dismiss(animated: true)
            let oid = code.split(separator: ":")[1]
            if let data = Data(base64Encoded: String(oid)) {
                do {
                    let decryptedData = try RNCryptor.decrypt(data: data, withPassword: "h47ESJ%hPuKCUCUkJQFr3AvnEU4*BwFV$nuPC&2y$BFk68Cx")
                    let decryptedString = String(data: decryptedData, encoding: .utf8) ?? "unknown"
                    print(decryptedString)
                    var url:String?
                    if decryptedString.hasSuffix("-0")  {
                        url = "http://192.168.0.20:8383/admin/qr/\(decryptedString.split(separator: "-")[0])"
                    } else {
                        url = "https://sdbot.ovidiu.me/admin/qr/\(decryptedString.split(separator: "-")[0])"
                    }
                    self.goto(url!)
                    
                } catch {
                    print(error)
                }
            }
            
        } else {
            let ac = UIAlertController(title: "QR Bread Details", message: "Invalid QR Code. No bread for you!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { alert -> Void in
                self.dismiss(animated: true)
            } ))
            present(ac, animated: true)
        }
    }
    
    func goto(_ url: String) {
        NotificationCenter.default.post(name: Notification.Name.ShowBackoffice, object: self, userInfo: ["goto":url])
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
