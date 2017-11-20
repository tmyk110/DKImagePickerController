//
//  DKAsset.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 15/12/13.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import Photos

public extension CGSize {
	
	public func toPixel() -> CGSize {
		let scale = UIScreen.main.scale
		return CGSize(width: self.width * scale, height: self.height * scale)
	}
}

@objc
public enum DKAssetType : Int {
    
    case photo
    
    case video
    
}

/**
 An `DKAsset` object represents a photo or a video managed by the `DKImagePickerController`.
 */
open class DKAsset: NSObject {
	
	@objc open private(set) var type: DKAssetType = .photo
	
    /// Returns location, if its contained in original asser
    @objc open private(set) var location: CLLocation?
    
	/// play time duration(seconds) of a video.
	open private(set) var duration: Double?
	
	@objc open private(set) var originalAsset: PHAsset?
    
    @objc open var localIdentifier: String
        
    /// Returns a UIImage that is appropriate for displaying full screen.
    private var fullScreenImage: (image: UIImage?, info: [AnyHashable: Any]?)?
		
	public init(originalAsset: PHAsset) {
        self.localIdentifier = originalAsset.localIdentifier
        self.location = originalAsset.location
		super.init()
		
		self.originalAsset = originalAsset
		
		let assetType = originalAsset.mediaType
		if assetType == .video {
			self.type = .video
			self.duration = originalAsset.duration
        }
	}
	
	internal var image: UIImage?
	internal init(image: UIImage) {
        self.localIdentifier = String(image.hash)
		super.init()
        
		self.image = image
		self.fullScreenImage = (image, nil)
	}
	
	override open func isEqual(_ object: Any?) -> Bool {
        if let another = object as? DKAsset {
            return self.localIdentifier == another.localIdentifier
        }
        return false
	}
	
	@objc public func fetchImage(with size: CGSize, completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        self.fetchImage(with: size, options: nil, completeBlock: completeBlock)
	}
	
	@objc public func fetchImage(with size: CGSize, options: PHImageRequestOptions?, completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        self.fetchImage(with: size, options: options, contentMode: .aspectFit, completeBlock: completeBlock)
	}
	
	@objc public func fetchImage(with size: CGSize, options: PHImageRequestOptions?, contentMode: PHImageContentMode, completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
		if let _ = self.originalAsset {
            getImageDataManager().fetchImage(for: self, size: size, options: options, contentMode: contentMode, completeBlock: completeBlock)
		} else {
			completeBlock(self.image, nil)
		}
	}
	
	@objc public func fetchFullScreenImage(with completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        self.fetchFullScreenImage(sync: false, completeBlock: completeBlock)
	}
	
	/**
     Fetch an image with the current screen size.
     
     - parameter sync:          If true, the method blocks the calling thread until image is ready or an error occurs.
     - parameter completeBlock: The block is executed when the image download is complete.
	*/
	@objc public func fetchFullScreenImage(sync: Bool, completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
		if let (image, info) = self.fullScreenImage {
			completeBlock(image, info)
		} else {
			let screenSize = UIScreen.main.bounds.size
			
			let options = PHImageRequestOptions()
			options.deliveryMode = .highQualityFormat
			options.resizeMode = .exact
			options.isSynchronous = sync

            getImageDataManager().fetchImage(for: self, size: screenSize.toPixel(), options: options, contentMode: .aspectFit) { [weak self] image, info in
				guard let strongSelf = self else { return }
				
				strongSelf.fullScreenImage = (image, info)
				completeBlock(image, info)
			}
		}
	}
	
	@objc public func fetchOriginalImage(with completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        self.fetchOriginalImage(sync: false, completeBlock: completeBlock)
	}
	
	/**
     Fetch an image with the original size.
     
     - parameter sync:          If true, the method blocks the calling thread until image is ready or an error occurs.
     - parameter completeBlock: The block is executed when the image download is complete.
	*/
    @objc public func fetchOriginalImage(sync: Bool, completeBlock: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        if let _ = self.originalAsset {
            let options = PHImageRequestOptions()
            options.version = .current
            options.isSynchronous = sync
            
            getImageDataManager().fetchImageData(for: self, options: options, completeBlock: { (data, info) in
                var image: UIImage?
                if let data = data {
                    image = UIImage(data: data)
                }
                completeBlock(image, info)
            })
        } else {
            completeBlock(self.image, nil)
        }
	}
    
    /**
     Fetch an image data with the original size.
     
     - parameter sync:          If true, the method blocks the calling thread until image is ready or an error occurs.
     - parameter completeBlock: The block is executed when the image download is complete.
     */
    @objc public func fetchImageData(sync: Bool, completeBlock: @escaping (_ imageData: Data?, _ info: [AnyHashable: Any]?) -> Void) {
        let options = PHImageRequestOptions()
        options.version = .current
        options.isSynchronous = sync
        
        getImageDataManager().fetchImageData(for: self, options: options, completeBlock: { (data, info) in
            completeBlock(data, info)
        })
    }
	
    /**
     Fetch an AVAsset with a completeBlock.
	*/
	@objc public func fetchAVAsset(with completeBlock: @escaping (_ AVAsset: AVAsset?, _ info: [AnyHashable: Any]?) -> Void) {
        self.fetchAVAsset(options: nil, completeBlock: completeBlock)
	}
	
    /**
     Fetch an AVAsset with a completeBlock and PHVideoRequestOptions.
     */
	@objc public func fetchAVAsset(options: PHVideoRequestOptions?, completeBlock: @escaping (_ AVAsset: AVAsset?, _ info: [AnyHashable: Any]?) -> Void) {
        getImageDataManager().fetchAVAsset(for: self, options: options, completeBlock: completeBlock)
	}
	
    /**
     Sync fetch an AVAsset with a completeBlock and PHVideoRequestOptions.
     */
	@objc public func fetchAVAsset(sync: Bool, options: PHVideoRequestOptions?, completeBlock: @escaping (_ AVAsset: AVAsset?, _ info: [AnyHashable: Any]?) -> Void) {
		if sync {
			let semaphore = DispatchSemaphore(value: 0)
            self.fetchAVAsset(options: options, completeBlock: { (AVAsset, info) -> Void in
				completeBlock(AVAsset, info)
				semaphore.signal()
			})
			_ = semaphore.wait(timeout: DispatchTime.distantFuture)
		} else {
            self.fetchAVAsset(options: options, completeBlock: completeBlock)
		}
	}
	
}

public extension DKAsset {
	
	struct DKAssetWriter {
		static let writeQueue: OperationQueue = {
			let queue = OperationQueue()
			queue.name = "DKAsset_Write_Queue"
			queue.maxConcurrentOperationCount = 5
			return queue
		}()
	}
	
	
    /**
     Writes the image in the receiver to the file specified by a given path.
     */
	@objc public func writeImage(to path: String, completeBlock: @escaping (_ success: Bool) -> Void) {
        if let _ = self.originalAsset {
            let options = PHImageRequestOptions()
            options.version = .current
            
            getImageDataManager().fetchImageData(for: self, options: options, completeBlock: { (data, _) in
                DKAssetWriter.writeQueue.addOperation({
                    if let imageData = data {
                        try? imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                        completeBlock(true)
                    } else {
                        completeBlock(false)
                    }
                })
            })
        } else {
            try! UIImageJPEGRepresentation(self.image!, 1)!.write(to: URL(fileURLWithPath: path))
            completeBlock(true)
        }
	}
	
    /**
     Writes the AVAsset in the receiver to the file specified by a given path.
     
     - parameter presetName:        An NSString specifying the name of the preset template for the export. See AVAssetExportPresetXXX.
     - parameter outputFileType:    Type of file to export. Should be a valid media type, otherwise export will fail. See AVFileType.
     */
    @objc public func writeAVAsset(to path: String, presetName: String, outputFileType: AVFileType = AVFileType.mov, completeBlock: @escaping (_ success: Bool) -> Void) {
        self.fetchAVAsset(options: nil) { (avAsset, _) in
            DKAssetWriter.writeQueue.addOperation({
                if let avAsset = avAsset,
                    let exportSession = AVAssetExportSession(asset: avAsset, presetName: presetName) {
                    exportSession.outputFileType = outputFileType
                    exportSession.outputURL = URL(fileURLWithPath: path)
                    exportSession.shouldOptimizeForNetworkUse = true
                    exportSession.exportAsynchronously(completionHandler: {
                        completeBlock(exportSession.status == .completed ? true : false)
                    })
                } else {
                    completeBlock(false)
                }
            })
        }
    }
}

public extension AVAsset {
	
	@objc public func calculateFileSize() -> Float {
		if let URLAsset = self as? AVURLAsset {
			var size: AnyObject?
			try! (URLAsset.url as NSURL).getResourceValue(&size, forKey: URLResourceKey.fileSizeKey)
			if let size = size as? NSNumber {
				return size.floatValue
			} else {
				return 0
			}
		} else if let _ = self as? AVComposition {
			var estimatedSize: Float = 0.0
			var duration: Float = 0.0
			for track in self.tracks {
				let rate = track.estimatedDataRate / 8.0
				let seconds = Float(CMTimeGetSeconds(track.timeRange.duration))
				duration += seconds
				estimatedSize += seconds * rate
			}
			return estimatedSize
		} else {
			return 0
		}
	}
    
}