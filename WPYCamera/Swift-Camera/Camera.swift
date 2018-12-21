//
//  MyCamera.swift
//  MyImGuider
//
//  Created by 王鹏宇 on 10/15/18.
//  Copyright © 2018 王鹏宇. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class Camera: UIViewController,AVCapturePhotoCaptureDelegate {
    
    
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var changeBtn: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    
    @IBOutlet weak var thumbImageView: UIImageView!
    
    
    var imageView : UIImageView!
    var focusView : UIView!
    var image : UIImage = UIImage()
    
    // 捕获设备 通常是前置摄像头 后置摄像头， 麦克风（音频输入）
    var device : AVCaptureDevice?
    
    // AVCaptureDeviceInput 输入设备 它使用 AVCaptureDevice 来初始化
    var inputDevice : AVCaptureDeviceInput?
    // 当启动摄像头开始捕获输入
    var output : AVCaptureMetadataOutput?
    var imageOutPut : AVCaptureStillImageOutput?
    // 由它把输入输出结合在一起， 并开始启动捕获设备（摄像头）
    var session : AVCaptureSession!
    
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    var isFlashOn : Bool = false
    var canCa : Bool = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IsOk()
        setup()
        initCamera()
    }

    
    @IBAction func back(_ sender: UIButton) {
        
        
//        self.session.stopRunning()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func changeCamera(_ sender: UIButton) {
        
        //1 获取之前的摄像头
        guard var position = self.inputDevice?.device.position else {return}
        //2 获取当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //3 创建新的device
        
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        guard let device = devices.filter({$0.position == position}).first else {
            return
        }
        
        let animation = CATransition()
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType(rawValue: "oglFlip")
        
        animation.subtype = (position == .front) ? CATransitionSubtype.fromLeft : CATransitionSubtype.fromRight
        
       //4 根据新的device创建新的input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {return}
        
        self.previewLayer .add(animation, forKey: nil)
        //5 在session中 切换 inout
        session.beginConfiguration()
        session.removeInput(self.inputDevice!)
        if session.canAddInput(videoInput){
             session.addInput(videoInput)
        }
       
        session.commitConfiguration()
        
        self.inputDevice = videoInput
    }
    
    @IBAction func flashAction(_ sender: UIButton) {
        
        try? device?.lockForConfiguration()
        switch device?.flashMode.rawValue {
        case 0:
            device!.flashMode = AVCaptureDevice.FlashMode.on
            self.flashBtn.setImage(UIImage(named: "闪光灯-开")
                , for: .normal)
            break
        case 1:
            device?.flashMode = AVCaptureDevice.FlashMode.auto
            self.flashBtn.setImage(UIImage(named: "闪光灯-关")
                , for: .normal)
            break
        default:
            
            device!.flashMode = AVCaptureDevice.FlashMode.off
            self.flashBtn.setImage(UIImage(named: "闪光灯-关")
                , for: .normal)
        }
        
        device?.unlockForConfiguration()
    }
    
    
    @IBAction func takePhotosAction(_ sender: UIButton) {
        
    
        let status = PHPhotoLibrary.authorizationStatus()
        if status == PHAuthorizationStatus.authorized {
            
          self.shutterCamera()
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            
            if status == PHAuthorizationStatus.restricted || status == PHAuthorizationStatus.denied || status == PHAuthorizationStatus.notDetermined {
                
                let alertVC = UIAlertController(title: "提示", message: "照片权限，未授权", preferredStyle: UIAlertController.Style.actionSheet)
                
                let goAction =  UIAlertAction(title: "去设置", style: UIAlertAction.Style.default) { (UIAlertAction) in
                    
                    if  let url = URL(string: UIApplication.openSettingsURLString){
                        if UIApplication.shared.canOpenURL(url){
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
                alertVC.addAction(goAction)
                self.present(alertVC, animated: true, completion: nil)
                
            }else {
                self.shutterCamera()
            }
        }
    }
    
    
    func shutterCamera(){
       
        let videoConnection : AVCaptureConnection? = imageOutPut?.connection(with: AVMediaType.video)
        
        if videoConnection == nil {
            print("take photo failed")
            
            return
        }
      
        self.imageOutPut?.captureStillImageAsynchronously(from: videoConnection ?? AVCaptureConnection()) { (_ imageDataSampleBuffer : CMSampleBuffer?, _ error : Error?) in
            
            if imageDataSampleBuffer == nil {
                return
            }
            
            guard let imageData : Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!) else {return} //照片数据流
            
            if let sampleImage = UIImage(data: imageData){
                self.image = sampleImage
                
                
                self.saveImageToPhotoAlbum(image: self.image)
            }
        }
        
    }
    
    
    
    func saveImageToPhotoAlbum(image : UIImage){
    
        
        UIImageWriteToSavedPhotosAlbum(image, self,  #selector(saveImage(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func saveImage(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        
        if error != nil{
            print("图片保存失败")
        }else{
           self.thumbImageView.image = image
        }
        
        
    }
}



extension Camera {
    
    func IsOk() {
        
        //相机权限
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        //此应用程序没有被授权访问的照片数据。可能是家长控制权限
        //用户已经明确否认了这一照片数据的应用程序访问
        if authStatus == AVAuthorizationStatus.restricted || authStatus == AVAuthorizationStatus.denied {
            
            let alertVC = UIAlertController(title: "提示", message: "照相机权限，未授权", preferredStyle: UIAlertController.Style.actionSheet)
            
            let goAction =  UIAlertAction(title: "去设置", style: UIAlertAction.Style.default) { (UIAlertAction) in
                
                if  let url = URL(string: UIApplication.openSettingsURLString){
                    if UIApplication.shared.canOpenURL(url){
                        UIApplication.shared.openURL(url)
                    }
                }
            }
         alertVC.addAction(goAction)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    
    func setup(){
        
        focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        
        focusView.layer.borderColor = UIColor.green.cgColor
        focusView.layer.borderWidth = 1.0
        focusView.backgroundColor = UIColor.clear
        self.view.addSubview(focusView)
        focusView.isHidden = true
        focusView.layer.cornerRadius = 5
        let tap = UITapGestureRecognizer(target: self, action: #selector(focusGesture(tap:)))
        
        self.view.addGestureRecognizer(tap)
        
        flashBtn.setImage(UIImage(named: "闪光灯-关"), for: .normal)
        isFlashOn = false
        
        
        let tap2 = UITapGestureRecognizer(target: self, action:#selector(goBigImage))
        self.thumbImageView.addGestureRecognizer(tap2)
        self.thumbImageView.isUserInteractionEnabled = true
    }
    
    func initCamera(){
        
        //使用AVMediaType.video 指明self.device 代表视频 默认使用后置摄像头进行初始化
       
        
        guard let dev = AVCaptureDevice.default(for: AVMediaType.video) else {
            
            return
        }
         self.device = dev
        
        //使用设备初始化输入
        self.inputDevice = try? AVCaptureDeviceInput(device:device!)
        
        //生成输出对象
        self.output = AVCaptureMetadataOutput()
        self.imageOutPut = AVCaptureStillImageOutput()
        
        //生成会话，用来结合输出
        self.session = AVCaptureSession()
        
        
        if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: "AVCaptureSessionPreset1280x720")){
            
            self.session.sessionPreset = .photo
        }
        
        if self.session.canAddInput(self.inputDevice!){
            self.session.addInput(self.inputDevice!)
        }
        
        if self.session.canAddOutput(self.imageOutPut!){
            
            self.session.addOutput(self.imageOutPut!)
        }
        
        //使用 self.session. 初始化预览层  self.session负责驱动input信息采集layer
        //负责把图像渲染显示
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.insertSublayer(self.previewLayer, below: self.photoButton.layer)
        
        //开始启动
        self.session.startRunning()
        
        
        
        if (try? device?.lockForConfiguration()) != nil {
            
            if (device?.isFlashModeSupported(.auto)) != nil {
                 device?.flashMode = .auto
            
            }
            //自动白平衡
            if device?.isWhiteBalanceModeSupported(.autoWhiteBalance) ?? false{
                
                device?.whiteBalanceMode = .autoWhiteBalance
            }
            
            if let flag = device?.hasFlash{
                
                if !flag {return}
            }
            
            if device?.flashMode == .on || device?.flashMode == .off {
                
                device?.flashMode = .off
                self.isFlashOn = false
                self.flashBtn.setImage(UIImage(named: "闪光灯-关")
                    , for: .normal)
            }
            
           device?.unlockForConfiguration()
        }

    }
    
    @objc func goBigImage(){
        
        setupBrowser(images: [self.image], index: 0) { (next) -> UIView? in
            
          return  self.thumbImageView
        }
    }
    
    @objc func focusGesture(tap : UITapGestureRecognizer){
        
        let point = tap.location(in: tap.view)
        self.focusAtPoint(point: point)
    }
    
    func focusAtPoint(point : CGPoint){
        
        let size = self.view.bounds.size
        let  focusPoint = CGPoint(x: point.y / size.height, y: 1 - point.x / size.width)
        
        if ((try? device?.lockForConfiguration()) != nil) {
            
            if let flag = self.device?.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus),flag == true {
                self.device?.focusPointOfInterest = focusPoint
                self.device?.focusMode = AVCaptureDevice.FocusMode.autoFocus
            }
            
            if let flag2 = self.device?.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose),flag2 == true {
                
                self.device?.exposurePointOfInterest = focusPoint
                self.device?.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            }
            
            self.device?.unlockForConfiguration()
            self.focusView.center = point
            self.focusView.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            }) { (finished) in
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.focusView.transform = CGAffineTransform(scaleX: 0, y: 0)
                }, completion: { (finished) in
                    
                    self.focusView.isHidden = true
                })
            }
            
        }
    }
    
    
}


import SKPhotoBrowser

// MARK: - 配置点击浏览大图
extension UIViewController : SKPhotoBrowserDelegate {
    
    
    private struct BrowserStoreKey {
        
        static var browserViewKey = "browserViewKey"
    }
    
    private var browserView:((_ index:Int) -> UIView?)? {
        
        set {
            
            objc_setAssociatedObject(self, &BrowserStoreKey.browserViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            
            return objc_getAssociatedObject(self, &BrowserStoreKey.browserViewKey) as? ((Int) -> UIView?)
        }
    }
    
    func setupBrowser(images:[Any]?,index:Int,browserView:((_ index:Int) -> UIView?)? = nil) {
        
        guard let images = images else { return }
       
        DispatchQueue.once(token: "skconfig") {
            SKPhotoBrowserOptions.displayAction = false
            SKPhotoBrowserOptions.displayStatusbar = true
            SKPhotoBrowserOptions.displayCounterLabel = true
            SKPhotoBrowserOptions.displayBackAndForwardButton = true
            SKPhotoBrowserOptions.enableSingleTapDismiss = true
            SKPhotoBrowserOptions.displayStatusbar = true
        }
        
        self.browserView = browserView
        
        let photos = images.compactMap { image -> SKPhoto? in
            
            if let image = image as? String  {
                
                return SKPhoto.photoWithImageURL(image, holder: nil)
            }
            
            if let image = image as? UIImage {
                
                return SKPhoto.photoWithImage(image)
            }
            
            return nil
        }
        
        let browser = SKPhotoBrowser(photos: photos, initialPageIndex: index)
        browser.cancelTitle = "cancel"
        browser.delegate = self
//        browser.setNavBarStyle(.transparency)
        
        self.present(browser, animated: true, completion: nil)
    }
    
    public func viewForPhoto(_ browser: SKPhotoBrowser, index: Int) -> UIView? {
        
        let view = self.browserView?(index)
        
        return view
    }
}


extension DispatchQueue {
    
    private static var onceTracker = [String]()
    
    //Executes a block of code, associated with a unique token, only once.  The code is thread safe and will only execute the code once even in the presence of multithreaded calls.
    public class func once(token: String, block: () -> Void)
    {   // 保证被 objc_sync_enter 和 objc_sync_exit 包裹的代码可以有序同步地执行
        objc_sync_enter(self)
        defer { // 作用域结束后执行defer中的代码
            objc_sync_exit(self)
        }
        
        if onceTracker.contains(token) {
            return
        }
        
        onceTracker.append(token)
        block()
    }
}
