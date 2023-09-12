import CropViewController
import Photos
import TLPhotoPicker
import UIKit

extension TLPhotosPickerConfigure {
    var isPreview: Bool {
        get { return true }
        set {}
    }

    var isCrop: Bool {
        get { return true }
        set {}
    }
}

var config = TLPhotosPickerConfigure()

@objc(MultipleImagePicker)
class MultipleImagePicker: NSObject, TLPhotosPickerViewControllerDelegate, UINavigationControllerDelegate, TLPhotosPickerLogDelegate, CropViewControllerDelegate {
    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    var window: UIWindow?
    var bridge: RCTBridge!
    var selectedAssets = [TLPHAsset]()
    var options = NSMutableDictionary()
    var videoAssets = [PHAsset]()
    var videoCount = 0
    var imageRequestOptions = PHImageRequestOptions()
    var videoRequestOptions = PHVideoRequestOptions()
    
    // controller
    
    // resolve/reject assets
    var resolve: RCTPromiseResolveBlock!
    var reject: RCTPromiseRejectBlock!
    
    func selectedCameraCell(picker: TLPhotosPickerViewController) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let cell = picker.collectionView(picker.collectionView, cellForItemAt: IndexPath(row: at, section: 0)) as! Cell
        if cell.asset?.mediaType == PHAssetMediaType.video {
            self.videoCount -= 1
        }
    }
    
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @objc(openPicker:withResolver:withRejecter:)
    func openPicker(options: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        self.setConfiguration(options: options, resolve: resolve, reject: reject)
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        
        viewController.didExceedMaximumNumberOfSelection = { [weak self] picker in
            self?.showExceededMaximumAlert(vc: picker, isVideo: false)
        }
        viewController.configure = config
        viewController.selectedAssets = self.selectedAssets
        viewController.logDelegate = self
    
        DispatchQueue.main.async {
            viewController.modalTransitionStyle = .coverVertical
            viewController.modalPresentationStyle = .fullScreen
            
            self.getTopMostViewController()?.present(viewController, animated: true, completion: nil)
        }
    }
    
    func setConfiguration(options: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolve
        self.reject = reject
        
        for key in options.keyEnumerator() {
            if key as! String != "selectedAssets" {
                self.options.setValue(options[key], forKey: key as! String)
            }
        }
        
        // set image / video request option.
        self.imageRequestOptions.deliveryMode = .fastFormat
        self.imageRequestOptions.resizeMode = .fast
        self.imageRequestOptions.isNetworkAccessAllowed = true
        self.imageRequestOptions.isSynchronous = false
        self.videoRequestOptions.version = PHVideoRequestOptionsVersion.current
        self.videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
        self.videoRequestOptions.isNetworkAccessAllowed = true
        
        // config options
        config.tapHereToChange = self.options["tapHereToChange"] as! String
        config.numberOfColumn = self.options["numberOfColumn"] as! Int
        config.cancelTitle = self.options["cancelTitle"] as! String
        config.doneTitle = self.options["doneTitle"] as! String
        config.emptyMessage = self.options["emptyMessage"] as! String
        config.selectMessage = self.options["selectMessage"] as! String
        config.deselectMessage = self.options["deselectMessage"] as! String
        config.usedCameraButton = self.options["usedCameraButton"] as! Bool
        config.usedPrefetch = self.options["usedPrefetch"] as! Bool
        config.allowedLivePhotos = self.options["allowedLivePhotos"] as! Bool
        config.allowedVideo = self.options["allowedVideo"] as! Bool
        config.allowedAlbumCloudShared = self.options["allowedAlbumCloudShared"] as! Bool
        config.allowedVideoRecording = self.options["allowedVideoRecording"] as! Bool
        config.maxVideoDuration = self.options["maxVideoDuration"] as? TimeInterval
        config.autoPlay = self.options["autoPlay"] as! Bool
        config.muteAudio = self.options["muteAudio"] as! Bool
        config.singleSelectedMode = (self.options["singleSelectedMode"])! as! Bool
        config.maxSelectedAssets = self.options["maxSelectedAssets"] as? Int
        config.selectedColor = UIColor(hex: self.options["selectedColor"] as! String)
        
        config.isPreview = self.options["isPreview"] as? Bool ?? false
        
        let mediaType = self.options["mediaType"] as! String
        
        config.mediaType = mediaType == "video" ? PHAssetMediaType.video : mediaType == "image" ? PHAssetMediaType.image : nil
        
        config.nibSet = (nibName: "Cell", bundle: MultipleImagePickerBundle.bundle())
        
        config.allowedPhotograph = self.options["allowedPhotograph"] as! Bool
        //        configure.preventAutomaticLimitedAccessAlert = self.options["preventAutomaticLimitedAccessAlert"]
        
        if options["selectedAssets"] != nil {
            self.handleSelectedAssets(selectedList: options["selectedAssets"] as! NSArray)
        }
    }
    
    func handleSelectedAssets(selectedList: NSArray) {
        let assetsExist = selectedList.filter { ($0 as! NSObject).value(forKey: "localIdentifier") != nil }
        self.videoCount = selectedList.filter { ($0 as! NSObject).value(forKey: "type") as? String == "video" }.count

        var assets = [TLPHAsset]()
        for index in 0 ..< assetsExist.count {
            let value = assetsExist[index]
            let localIdentifier = (value as! NSObject).value(forKey: "localIdentifier") as! String
            if !localIdentifier.isEmpty {
                var TLAsset = TLPHAsset.asset(with: localIdentifier)
                TLAsset?.selectedOrder = index + 1
                assets.insert(TLAsset!, at: index)
            }
        }
        self.selectedAssets = assets
        self.videoCount = assets.filter { $0.phAsset?.mediaType == .video }.count
    }

    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        return false
    }
    
    func photoPickerDidCancel() {
        self.reject("PICKER_CANCELLED", "User has canceled", nil)
    }
    
    internal func dismissLoading() {
        if let vc = self.getTopMostViewController()?.presentedViewController, vc is UIAlertController {
            self.getTopMostViewController()?.dismiss(animated: false, completion: nil)
        }
    }
    
    func dismissComplete() {
        DispatchQueue.main.async {
            self.getTopMostViewController()?.dismiss(animated: true, completion: nil)
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        let filePath = getImagePathFromUIImage(uiImage: image, prefix: "crop")
        let TLAsset = self.selectedAssets.first
        
        // Dismiss twice for crop controller & picker controller
        DispatchQueue.main.async {
            self.getTopMostViewController()?.dismiss(animated: true, completion: {
                self.getTopMostViewController()?.dismiss(animated: true, completion: {
                    if filePath != "", TLAsset != nil {
                        self.fetchAsset(TLAsset: TLAsset!) { object in
                            
                            object.data!["crop"] = [
                                "height": image.size.height,
                                "width": image.size.width,
                                "path": filePath,
                            ]
                            
                            self.resolve([object.data])
                        }
                    }
                })
            })
        }
    }
    
    func presentCropViewController(image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: (self.options["isCropCircle"] as! Bool) ? .circular : .default, image: image)
        cropViewController.delegate = self
        cropViewController.doneButtonTitle = config.doneTitle
        cropViewController.doneButtonColor = config.selectedColor
        
        cropViewController.cancelButtonTitle = config.cancelTitle
        
        self.getTopMostViewController()?.present(cropViewController, animated: true, completion: nil)
    }
    
    func fetchAsset(TLAsset: TLPHAsset, completion: @escaping (MediaResponse) -> Void) {
        TLAsset.tempCopyMediaFile(videoRequestOptions: self.videoRequestOptions, imageRequestOptions: self.imageRequestOptions, livePhotoRequestOptions: nil, exportPreset: AVAssetExportPresetHighestQuality, convertLivePhotosToJPG: true, progressBlock: { _ in
        }, completionBlock: { filePath, fileType in
            
            let object = MediaResponse(filePath: filePath.absoluteString, mime: fileType, withTLAsset: TLAsset, isExportThumbnail: self.options["isExportThumbnail"] as! Bool)
            
            DispatchQueue.main.async {
                completion(object)
            }
        })
    }
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // check with asset picker
        if withTLPHAssets.count == 0 {
            self.resolve([])
            self.dismissComplete()
            return
        }
        
        // define count
        let withTLPHAssetsCount = withTLPHAssets.count
        let selectedAssetsCount = self.selectedAssets.count
        
        // check logic code for isCrop
        let cropCondition = (options["singleSelectedMode"] as! Bool) && (self.options["isCrop"] as! Bool) && withTLPHAssets.first?.type == .photo
        
        // check difference
        if withTLPHAssetsCount == selectedAssetsCount && withTLPHAssets[withTLPHAssetsCount - 1].phAsset?.localIdentifier == self.selectedAssets[selectedAssetsCount - 1].phAsset?.localIdentifier && !cropCondition {
            self.dismissComplete()
            return
        }
        
        self.selectedAssets = withTLPHAssets
        
        if cropCondition {
            let uiImage = withTLPHAssets.first?.fullResolutionImage
            if uiImage != nil {
                self.presentCropViewController(image: (withTLPHAssets.first?.fullResolutionImage)!)
                return
            }
        }
        
        let selections = NSMutableArray(array: withTLPHAssets)
        
        // add loading view
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        
        if #available(iOS 13.0, *) {
            loadingIndicator.color = .secondaryLabel
        } else {
            loadingIndicator.color = .black
        }
        
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        
        // handle controller
        self.getTopMostViewController()?.present(alert, animated: true, completion: {
            let group = DispatchGroup()
            
            for TLAsset in withTLPHAssets {
                group.enter()
                self.fetchAsset(TLAsset: TLAsset) { object in
                    let index = TLAsset.selectedOrder - 1
                    selections[index] = object.data as Any
                    group.leave()
                }
            }
            
            group.notify(queue: .main) { [self] in
                self.resolve(selections)
                DispatchQueue.main.async {
                    alert.dismiss(animated: true, completion: {
                        self.dismissComplete()
                    })
                }
            }
        })
    }
    
    func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }
        return topMostViewController
    }
    
    func showExceededMaximumAlert(vc: UIViewController, isVideo: Bool) {
        let alert = UIAlertController(title: self.options["maximumMessageTitle"] as? String, message: self.options[isVideo ? "maximumVideoMessage" : "maximumMessage"] as? String, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.options["messageTitleButton"] as? String, style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    func canSelectAsset(phAsset: PHAsset) -> Bool {
        let maxVideo = self.options["maxVideo"]
        if phAsset.mediaType == .video {
            if self.videoCount == maxVideo as! Int && !(self.options["singleSelectedMode"] as! Bool) {
                self.showExceededMaximumAlert(vc: self.getTopMostViewController()!, isVideo: true)
                return false
            }
            self.videoCount += 1
        }
        return true
    }
}

extension UIViewController {
    func getTopVC() -> UIViewController? {
        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }
        return topMostViewController
    }
}

extension UIColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if (cString.count) != 6 {
            self.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0) // Màu mặc định nếu chuỗi không hợp lệ
        } else {
            var rgbValue: UInt64 = 0
            Scanner(string: cString).scanHexInt64(&rgbValue)
            
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: CGFloat(1.0)
            )
        }
    }
}
