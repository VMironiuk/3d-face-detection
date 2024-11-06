//
//  CameraFrameManager.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import AVFoundation
import Vision

final class CameraFrameManager: NSObject, ObservableObject {
  private let sequenceHandler = VNSequenceRequestHandler()
  private var isAnyFaceDetected = false
  private var framesCount = 0
  private var useDisparity = false
  
  @Published private(set) var currentFrame: CVPixelBuffer?
  @Published private(set) var depthFrame: CVPixelBuffer?
  @Published private(set) var isFaceDetected: Bool = false
  @Published private(set) var depth = DetectionRecordItem(type: .depth, value: 0.0)
  @Published private(set) var faceBoxX = DetectionRecordItem(type: .boxX, value: 0.0)
  @Published private(set) var faceBoxY = DetectionRecordItem(type: .boxY, value: 0.0)
  @Published private(set) var faceBoxWidth = DetectionRecordItem(type: .boxWidth, value: 0.0)
  @Published private(set) var faceBoxHeight = DetectionRecordItem(type: .boxHeight, value: 0.0)
  
  private var faceBoundingBox: CGRect = .zero
    
  func useDisparity(_ useDisparity: Bool) {
    self.useDisparity = useDisparity
  }
  
  override init() {
    super.init()
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

extension CameraFrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
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

extension CameraFrameManager: AVCaptureDepthDataOutputDelegate {
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
    
    let depthValue = calculateDepthAverage(
      depthPointer: depthPointer,
      width: width,
      height: height
    )
    
    CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
    
    DispatchQueue.main.async { [weak self] in
      let depthRecord = DetectionRecordItem(
        type: self?.useDisparity == true ? .disparity : .depth,
        value: depthValue
      )
      self?.depth = depthRecord
      
      self?.isFaceDetected = depthRecord.isMatching
    }
  }
  
  /// Note that the matrix constructed from the `depthPointer` represents a frame
  /// rotated 90 degrees counter-clockwise comparing to the device's screen users see
  private func calculateDepthAverage(
    depthPointer: UnsafePointer<Float32>,
    width: Int,
    height: Int
  ) -> Float32 {
    let headAreaMinX = width / 5 * 2
    let headAreaMaxX = width / 5 * 3
    let headAreaMinY = height / 3
    let headAreaMaxY = height / 3 * 2
    
    var headDepthValuesCounter: Float32 = 0.0
    var headDepthValuesSum: Float32 = 0.0
    
    for y in headAreaMinY..<headAreaMaxY {
      for x in headAreaMinX..<headAreaMaxX {
        headDepthValuesSum += depthPointer[y * width + x]
        headDepthValuesCounter += 1
      }
    }
    
    return headDepthValuesSum / headDepthValuesCounter
  }
  
  /// Note that the face's bounding box is 90 degrees rotated counter-clockwise that's why when
  /// a user rotates a device around y axis there are changes in the bounding box's minY instead
  /// of minX and vice versa
  private func isFaceBoundingBoxAllowed(_ box: CGRect) -> Bool {
    faceBoxX = .init(type: .boxX, value: Float32(box.minY))
    faceBoxY = .init(type: .boxY, value: Float32(box.minX))
    faceBoxWidth = .init(type: .boxWidth, value: Float32(box.width))
    faceBoxHeight = .init(type: .boxHeight, value: Float32(box.height))
    
    return faceBoxX.isMatching
    && faceBoxY.isMatching
    && faceBoxWidth.isMatching
    && faceBoxHeight.isMatching
  }
}
