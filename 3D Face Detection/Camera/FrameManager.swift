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
  
  @Published private(set) var currentFrame: CVPixelBuffer?
  @Published private(set) var isFaceDetected: Bool = false
  @Published private(set) var innerDepth: Float32 = 0.0
  @Published private(set) var outerDepth: Float32 = 0.0
  @Published private(set) var depthDiff: Float32 = 0.0
  
  let videoOutputQueue = DispatchQueue(
    label: "com.vmyroniuk.VideoOutputQueue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem
  )
  
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
    guard isAnyFaceDetected else {
      isFaceDetected = false
      return
    }
    guard framesCount >= 10 else {
      framesCount += 1
      return
    }
    framesCount = 0
    
    let depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
    let depthDataMap = depthData.depthDataMap
    
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
      
      if innerDepthAverage < 2.0
          && innerDepthAverage > 1.75
          && innerDepthAverage - outerDepthAverage > 0.7
          && innerDepthAverage - outerDepthAverage < 1.0
      {
        self?.isFaceDetected = true
      } else {
        self?.isFaceDetected = false
      }
    }
  }
  
  private func calculateDepthAverages(
    depthPointer: UnsafePointer<Float32>,
    width: Int,
    height: Int
  ) -> (innerDepthAverage: Float32, outerDepthAverage: Float32
  ) {
    let innerMinX = width / 3
    let innerMinY = height / 3
    let innerRect = CGRect(x: innerMinX, y: innerMinY, width: innerMinX, height: innerMinY)
    
    var innerCounter: Float32 = 0.0
    var outerCounter: Float32 = 0.0
    var innerDepthValue: Float32 = 0.0
    var outerDepthValue: Float32 = 0.0
    for y in 0..<height {
      for x in 0..<width {
        let index = CGPoint(x: x, y: y)
        let depthValue = depthPointer[y * width + x]
        if innerRect.contains(index) {
          innerCounter += 1.0
          innerDepthValue += depthValue
        } else {
          outerCounter += 1.0
          outerDepthValue += depthValue
        }
      }
    }
    
    let innerDepthAverage = innerDepthValue / innerCounter
    let outerDepthAverage = outerDepthValue / outerCounter
    
    return (innerDepthAverage, outerDepthAverage)
  }  
}
