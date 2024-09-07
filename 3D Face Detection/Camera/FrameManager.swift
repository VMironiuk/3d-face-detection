//
//  FrameManager.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import AVFoundation
import Vision

final class FrameManager: NSObject, ObservableObject {
  static let shared = FrameManager()
  
  private let sequenceHandler = VNSequenceRequestHandler()
  private var isAnyFaceDetected = false
  private var framesCount = 0
  private var useDisparity = false
  
  @Published private(set) var currentFrame: CVPixelBuffer?
  @Published private(set) var depthFrame: CVPixelBuffer?
  @Published private(set) var isFaceDetected: Bool = false
  @Published private(set) var innerDepth: Float32 = 0.0
  @Published private(set) var outerDepth: Float32 = 0.0
  @Published private(set) var depthDiff: Float32 = 0.0
    
  private let videoOutputQueue = DispatchQueue(
    label: "com.vmyroniuk.VideoOutputQueue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem
  )
  
  func useDisparity(_ useDisparity: Bool) {
    self.useDisparity = useDisparity
  }
  
  private override init() {
    super.init()
    CameraManager.shared.set(videoDelegate: self, queue: videoOutputQueue)
    CameraManager.shared.set(depthDelegate: self, queue: videoOutputQueue)
  }
  
  private func detectedFace(request: VNRequest, error: Error?) {
    if let results = request.results as? [VNFaceObservation], results.first != nil {
      isAnyFaceDetected = true
    } else if let error {
      isAnyFaceDetected = false
      print("FACE::DETECTION_ERROR: \(error.localizedDescription)")
    } else {
      isAnyFaceDetected = false
    }
  }
}

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let imageBuffer = sampleBuffer.imageBuffer else {
      isAnyFaceDetected = false
      return
    }
    
    DispatchQueue.main.async {
      self.currentFrame = imageBuffer
    }
    
    let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)
    do {
      try sequenceHandler.perform(
        [detectFaceRequest],
        on: sampleBuffer,
        orientation: .leftMirrored)
    } catch {
      isAnyFaceDetected = false
      print("FACE_DETECTION_REQUEST::FAILURE", error.localizedDescription)
    }
  }
}

extension FrameManager: AVCaptureDepthDataOutputDelegate {
  func depthDataOutput(
    _ output: AVCaptureDepthDataOutput,
    didOutput depthData: AVDepthData,
    timestamp: CMTime,
    connection: AVCaptureConnection
  ) {
    let depthData = depthData.converting(
      toDepthDataType: useDisparity
      ? kCVPixelFormatType_DisparityFloat32
      : kCVPixelFormatType_DepthFloat32
    )
    let depthDataMap = depthData.depthDataMap
//    depthDataMap.normalize()
    
    DispatchQueue.main.async { [weak self] in
      self?.depthFrame = depthDataMap
    }

    guard isAnyFaceDetected else {
      isFaceDetected = false
      return
    }
    guard framesCount >= 10 else {
      framesCount += 1
      return
    }
    framesCount = 0
        
    CVPixelBufferLockBaseAddress(depthDataMap, .readOnly)
    
    guard let baseAddress = CVPixelBufferGetBaseAddress(depthDataMap) else {
      CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
      return
    }
    
    let depthPointer = baseAddress.assumingMemoryBound(to: Float32.self)
    
    let width = CVPixelBufferGetWidth(depthDataMap)
    let height = CVPixelBufferGetHeight(depthDataMap)
    
    let (innerDepthAverage, outerDepthAverage) = calculateDepthAverages(
      depthPointer: depthPointer,
      width: width,
      height: height
    )
    
    CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
    
    DispatchQueue.main.async { [weak self] in
      self?.innerDepth = innerDepthAverage
      self?.outerDepth = outerDepthAverage
      self?.depthDiff = innerDepthAverage - outerDepthAverage

      self?.isFaceDetected = (innerDepthAverage >= 0.6 && innerDepthAverage <= 0.8)
    }
  }
  
  private func calculateDepthAverages(
    depthPointer: UnsafePointer<Float32>,
    width: Int,
    height: Int
  ) -> (headDepthAverage: Float32, outerDepthAverage: Float32
  ) {
    let rightOuterAreaMinX = width / 5 * 2
    let rightOuterAreaMinY = 0
    let rightOuterArea = CGRect(x: rightOuterAreaMinX, y: rightOuterAreaMinY, width: width / 5 * 2, height: height / 3)
    
    let leftOuterAreaMinX = width / 5 * 2
    let leftOuterAreaMinY = height / 3 * 2
    let leftOuterArea = CGRect(x: leftOuterAreaMinX, y: leftOuterAreaMinY, width: width / 5 * 2, height: height / 3)
    
    let headAreaMinX = width / 5 * 2
    let headAreaMinY = height / 3
    let headArea = CGRect(x: headAreaMinX, y: headAreaMinY, width: width / 5 * 2, height: height / 3)
    
    var outerDepthValuesCounter: Float32 = 0.0
    var headDepthValuesCounter: Float32 = 0.0
    var outerDepthValuesSum: Float32 = 0.0
    var headDepthValuesSum: Float32 = 0.0
    
    for y in 0..<height {
      for x in (width / 5 * 2)..<width {
        let index = CGPoint(x: x, y: y)
        let depthValue = depthPointer[y * width + x]
        if rightOuterArea.contains(index) || leftOuterArea.contains(index) {
          outerDepthValuesSum += depthValue
          outerDepthValuesCounter += 1
        } else if headArea.contains(index) {
          headDepthValuesSum += depthValue
          headDepthValuesCounter += 1
        }
      }
    }
    
    let outerDepthAverageValue = outerDepthValuesSum / outerDepthValuesCounter
    let headDepthAverageValue = headDepthValuesSum / headDepthValuesCounter
    
    return (headDepthAverageValue, outerDepthAverageValue)
  }
}

extension CVPixelBuffer {
  func normalize() {
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    
    var minPixel: Float = 1.0
    var maxPixel: Float = 0.0
    
    /// You might be wondering why the for loops below use `stride(from:to:step:)`
    /// instead of a simple `Range` such as `0 ..< height`?
    /// The answer is because in Swift 5.1, the iteration of ranges performs badly when the
    /// compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
    /// which is eactly what happens when running this sample project in Debug mode.
    /// If this was a production app then it might not be worth worrying about but it is still
    /// worth being aware of.
    
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = floatBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    
    let range = maxPixel - minPixel
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = floatBuffer[y * width + x]
        floatBuffer[y * width + x] = (pixel - minPixel) / range
      }
    }
    
    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
  }
}
