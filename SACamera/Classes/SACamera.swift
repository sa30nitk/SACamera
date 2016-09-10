//
//  SACamera.swift
//  Pods
//
//  Created by SATEESH on 06/09/16.
//
//

import UIKit

import UIKit
import AVFoundation
import QuartzCore
import Foundation



class SACameraContainer: UIView {
    
    var camera: SACamera!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize() {
        let cameraView = SACamera(imageType: .Jpeg)
        cameraView.frame = self.bounds
        self.addSubview(cameraView)
        cameraView.updateConstraints()
        self.camera = cameraView
    }
}


struct config {
    var orientations:[Int] = [0]
    var outputType:OutPutType = .Jpeg
    var outputScale = 1
    var outputSize = CGSize(width: 1000, height: 1000)
    var jPegCompression = 0
    var showOverlay = true
    var changeOrientaionOnCapturing = true
    var maxNumberOfImages = 10
    var imagesCollectionView = true
    var tourchEnabled = true
    var focusEnabled = true
    var sessionPreset = AVCaptureSessionPresetPhoto
    var flashEnabled = true
    var videoGravity = AVLayerVideoGravityResizeAspectFill
    var captureMode:CameraCaptureMode = .Photo
    var isPhotoCamera = true
    var imageSize:ImageSize = .Visible
}


enum OutPutType{
    case Jpeg,Png
}

enum ImageSize{
    case Full,Visible
}

enum CameraCaptureMode{
    case Photo,Video
}



class SACamera: UIView {
    
    // MARK: - Variables
    
    private let captureSession = AVCaptureSession()
    private var captureDevice:AVCaptureDevice?
    private var previewLayer:AVCaptureVideoPreviewLayer!
    private var stillImageoutput:AVCaptureStillImageOutput!
    private var isImageCapturing = false
    private var flashBtn: UIButton?
    private var flashMode:AVCaptureFlashMode = .auto
    private var imageOutPutType:OutPutType = .Jpeg
    private var imageSize:ImageSize = .Visible
    
    // private var blurView:BlurOrAlphaView?
    // MARK: - Initilization methods
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    convenience init(imageType: OutPutType) {
        self.init()
        imageOutPutType = imageType
    }
    
    deinit{
        self.captureSession.stopRunning();
        self.removeObserverForDeviceOrientaionChangeNotifications()
        self.removeCameraFocusChangeObserverForCaptureDevice()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if(newSuperview != nil){
            self.checkTheCameraAccess()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.previewLayer?.frame = self.bounds;
    }
    
    
    
    // MARK: - Initial setUpMethods
    
    
    class func checkTheCameraAccessWith(tittle: String, message: String,  completion: @escaping (_ granted: Bool) -> Void) {
        var isShowCameraPopUpRequired = false
        let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch(authorizationStatus){
        case .authorized:
            isShowCameraPopUpRequired = false
            completion(true)
            break
        case .denied:
            isShowCameraPopUpRequired = true
            completion(false)
            break
        case .restricted:
            isShowCameraPopUpRequired = true
            completion(false)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) -> Void in
                if(granted){
                    isShowCameraPopUpRequired = false
                    completion(true)
                }
                else{
                    isShowCameraPopUpRequired = false
                    completion(false)
                }
            })
            break
        }
        if(isShowCameraPopUpRequired ){
            SACamera.showAlertOnCameraPermissionDenied(tittle: tittle, message: message);
        }
    }
    
    class func showAlertOnCameraPermissionDenied(tittle:String , message: String){
        let actionSheetController: UIAlertController = UIAlertController(title: tittle , message: message , preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        let discardAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { action -> Void in
            UIApplication.shared.openURL(NSURL(string:UIApplicationOpenSettingsURLString)! as URL);
        }
        actionSheetController.addAction(discardAction)
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func checkTheCameraAccess(){
        SACamera.checkTheCameraAccessWith(tittle: NSLocalizedString("Add record camera enable notification tittle", comment: ""), message: NSLocalizedString("Add record camera enable Notification message", comment: "")) { (granted) in
            if(granted){
                self.initialSetUp()
            }
        }
    }
    
    func initialSetUp(){
        self.iniitalizeCamera()
        self.addflash()
        self.showFlash()
        self.startSession()
        // self.addBlurView()
    }
    
    func iniitalizeCamera(){
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
        let devices = AVCaptureDevice.devices()
        for device in devices!{
            if((device as AnyObject).hasMediaType(AVMediaTypeVideo)){
                if((device as AnyObject).position == AVCaptureDevicePosition.back){
                    self.captureDevice = device as? AVCaptureDevice;
                    self.addCameraFocusChangeObserverForCaptureDevice()
                }
            }
        }
        if let _ = self.captureDevice{
            self.beginSession()
            self.setOutput()
        }
        
        self.addDeviceOrientationChangeNotifications();
    }
    
    func changeReturnImageSize(imagesize:ImageSize){
        self.imageSize = imagesize
    }
    
    private func beginSession(){
        
        do{
            captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice!))
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewLayer?.frame = self.bounds;
            if let previewLayer = self.previewLayer{
                self.layer.insertSublayer(previewLayer, at: 0)
            }
            self.changeOreintation()
            self.changeFlash()
        }
        catch{
        }
        
    }
    
    
    
    private func setOutput(){
        self.stillImageoutput = AVCaptureStillImageOutput()
        self.stillImageoutput?.isHighResolutionStillImageOutputEnabled = true
        
        switch imageOutPutType{
        case .Jpeg:
            self.stillImageoutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            break;
        case .Png:
            self.stillImageoutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG,kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
            break;
        }
        if let stillImageoutput = self.stillImageoutput{
            self.captureSession.addOutput(stillImageoutput)
            
        }
        
    }
    
    func addflash(){
        if((self.captureDevice?.hasFlash) == true){
            self.flashBtn = UIButton()
            self.flashBtn?.translatesAutoresizingMaskIntoConstraints = false
            self.flashBtn?.setImage(UIImage(named: "flash_auto"), for: .normal)
            if let flashBtn = self.flashBtn{
                self.addSubview(flashBtn)
                let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[flashBtn(52)]-25-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["flashBtn":flashBtn])
                self.addConstraints(horizontalConstraints)
                let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[flashBtn(52)]-14-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["flashBtn":flashBtn])
                self.addConstraints(verticalConstraints)
                flashBtn.isHidden = true
            }
        }
    }
    
    func showFlash(){
        if((self.captureDevice?.hasFlash) == true){
            if let flashBtn = self.flashBtn{
                flashBtn.isHidden = false
            }
        }
    }
    
    
    // MARK: - Notification observerAndRemovers
    
    
    private func addDeviceOrientationChangeNotifications(){
    }
    
    private func removeObserverForDeviceOrientaionChangeNotifications(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    private func addCameraFocusChangeObserverForCaptureDevice(){
//        self.captureDevice?.addObserver(self, forKeyPath: "adjustingFocus", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    private func removeCameraFocusChangeObserverForCaptureDevice(){
        self.captureDevice?.removeObserver(self, forKeyPath: "adjustingFocus")
    }
    
    
    func deviceOrientationChanged(notification:NSNotification){
        self.changeOreintation()
    }
    
    private func changeOreintation(){
        let connection = previewLayer?.connection as AVCaptureConnection!
        if(connection?.isVideoOrientationSupported)!{
            switch(UIApplication.shared.statusBarOrientation){
            case UIInterfaceOrientation.portrait:
                self.previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait;
                break
            case UIInterfaceOrientation.portraitUpsideDown:
                self.previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown;
                break
            case UIInterfaceOrientation.landscapeLeft:
                self.previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft;
                break
            case UIInterfaceOrientation.landscapeRight:
                self.previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight;
                break
            default:
                self.previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight;
                break;
            }
        }
    }
    
    
    
    
    // MARK: - Button Actions
    
    func flashClicked(sender:UIButton){
        switch(self.flashMode){
        case .auto:
            flashMode = .on
            break
            
        case .on:
            flashMode = .off
            
            break
            
        case .off:
            flashMode = .auto
            
            break
        }
        self.changeFlash()
    }
    
    
    private func changeFlash(){
        if((self.captureDevice?.hasFlash) == true){
            if ((self.captureDevice?.isFlashModeSupported(self.flashMode)) == true){
                do{
                    try self.captureDevice?.lockForConfiguration()
                    if((self.captureDevice?.isFlashModeSupported(flashMode)) == true){
                        self.captureDevice?.flashMode = flashMode;
                    }
                    self.changeFlashImage(flashmode: (self.captureDevice?.flashMode)!)
                    
                }
                catch{
                    self.captureDevice?.unlockForConfiguration()
                }
                self.captureDevice?.unlockForConfiguration()
            }
        }
    }
    
    private func changeFlashImage(flashmode:AVCaptureFlashMode){
        switch(flashmode){
        case .auto:
            self.flashBtn?.setImage(UIImage(named: "flash_auto"), for: .normal)
            break
            
        case .on:
            self.flashBtn?.setImage(UIImage(named: "flash_on"), for: .normal)
            break
            
        case .off:
            self.flashBtn?.setImage(UIImage(named: "flash_off"), for: .normal)
            break
        }
    }
    
    func capturePhotoWithCompletionHandler(completion: @escaping ((UIImage!)->())){
        if(!isImageCapturing){
            isImageCapturing = true
            self.stillImageoutput?.captureStillImageAsynchronously(from: self.stillImageoutput?.connection(withMediaType: AVMediaTypeVideo), completionHandler: { (sampleBuffer, error) -> Void in
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = DispatchQueue.global(qos: .background)
                backgroundQueue.async {
                    var returnImage:UIImage?
                    self.pauseSession()
                    if(error == nil){
                        switch (self.imageOutPutType){
                        case .Jpeg:
                            var data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                            if ((data?.count)! / (1024 * 1024)  > 5){
                                if let da = data{
                                    let image = UIImage(data: da)
                                    data = UIImageJPEGRepresentation(image!, 0.5)
                                }
                            }
                            let image = UIImage(data: data!)
                            
                            switch (self.imageSize){
                            case .Full:
                                returnImage = image
                                break
                                
                            case .Visible:
                                let rect =  self.previewLayer?.metadataOutputRectOfInterest(for: (self.previewLayer?.bounds)!);
                                let width = (image?.cgImage)?.width
                                let height = (image?.cgImage)?.height
                                
                                
                                let rectForCapturedImage = CGRect(x: CGFloat(width!) * rect!.origin.x, y: CGFloat( height!) * rect!.origin.y, width:  CGFloat( width!) * rect!.size.width, height: CGFloat(height!) * rect!.size.height)
                                
                                let cgimageRef = image!.cgImage?.cropping(to: rectForCapturedImage)
                                if let cgimageRef = cgimageRef{
                                    //let croppedImage =  UIImage(CGImage: cgimageRef)
                                    returnImage = UIImage(cgImage: cgimageRef, scale: 1, orientation: UIImageOrientation.right)
                                }
                                break
                                
                            }
                            
                        case .Png:
                            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)
                            CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!)
                            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
                            let width1 = CVPixelBufferGetWidth(imageBuffer!)
                            let heifht1 = CVPixelBufferGetHeight(imageBuffer!)
                            let colorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: baseAddress, width: width1, height: heifht1, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
                            let quartzImage = context!.makeImage()
                            CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            
                            // Create an image object from the Quartz image
                            returnImage = UIImage(cgImage: quartzImage!, scale: 1, orientation: UIImageOrientation.right)
                            break
                        }
                        
                    }
                    self.startSession()
                    if let returnImage = returnImage{
                        completion(returnImage)
                    }
                    else{
                        completion(nil)
                    }
                    self.isImageCapturing = false
                    
                }
                
                
                
                
            });
        }
        else{
            completion(nil)
        }
        
    }
    
    // MARK: - Session management
    func startSession(){
        if(!captureSession.isRunning){
            captureSession.startRunning()
            
        }
        
    }
    
    func pauseSession(){
        if(captureSession.isRunning){
            captureSession.stopRunning()
        }
        
    }
    
    func stopSession(){
        if(captureSession.isRunning){
            captureSession.stopRunning()
        }
    }
    
}
