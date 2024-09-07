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
  @Published private(set) var faceBoxX: CGFloat = 0.0
  @Published private(set) var faceBoxY: CGFloat = 0.0
  @Published private(set) var faceBoxWidth: CGFloat = 0.0
  @Published private(set) var faceBoxHeight: CGFloat = 0.0
  
  private var faceBoundingBox: CGRect = .zero
    
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
    if let results = request.results as? [VNFaceObservation], let result = results.first {
      isAnyFaceDetected = true
      faceBoundingBox = result.boundingBox
    } else if let error {
      isAnyFaceDetected = false
      faceBoundingBox = .zero
      print("FACE::DETECTION_ERROR: \(error.localizedDescription)")
    } else {
      isAnyFaceDetected = false
      faceBoundingBox = .zero
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
    
    guard isFaceBoundingBoxAllowed(faceBoundingBox) else {
      isFaceDetected = false
      return
    }
        
    CVPixelBufferLockBaseAddress(depthDataMap, .readOnly)
    
    guard let baseAddress = CVPixelBufferGetBaseAddress(depthDataMap) else {
      CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
      return
    }
    
    let depthPointer = baseAddress.assumingMemoryBound(to: Float32.self)
    
    let width = CVPixelBufferGetWidth(depthDataMap)
    let height = CVPixelBufferGetHeight(depthDataMap)
    
    let (innerDepthAverage, _) = calculateDepthAverages(
      depthPointer: depthPointer,
      width: width,
      height: height
    )
    
    CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
    
    DispatchQueue.main.async { [weak self] in
      self?.innerDepth = innerDepthAverage

      self?.isFaceDetected = (innerDepthAverage >= 0.5 && innerDepthAverage <= 0.8)
    }
  }
  
  /// Note that the matrix constructed from the `depthPointer` represents a frame
  /// rotated 90 degrees counter-clockwise comparing to the device's screen users see
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
  
  /// Note that the face's bounding box is 90 degrees rotated counter-clockwise that's why when
  /// a user rotates a device around y axis there are changes in the bounding box's minY instead
  /// of minX and vice versa
  private func isFaceBoundingBoxAllowed(_ box: CGRect) -> Bool {
    faceBoxX = box.minY
    faceBoxY = box.minX
    faceBoxWidth = box.width
    faceBoxHeight = box.height
    
    return box.minY >= 0.2
    && box.minY <= 0.35
    && box.minX >= 0.3
    && box.minX <= 0.45
    && box.width >= 0.175
    && box.width <= 0.3
    && box.height >= 0.35
    && box.height <= 0.5
  }
}
