//
//  ContentViewModel.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import CoreImage
import Combine

final class ContentViewModel: ObservableObject {
  @Published private(set) var frame: CGImage?
  @Published private(set) var depthFrame: CGImage?
  @Published private(set) var error: Error?
  @Published private(set) var faceDetected: Bool = false
  @Published private(set) var depth = DetectionRecordItem(type: .depth, value: 0.0)
  @Published private(set) var faceBoxX = DetectionRecordItem(type: .boxX, value: 0.0)
  @Published private(set) var faceBoxY = DetectionRecordItem(type: .boxY, value: 0.0)
  @Published private(set) var faceBoxWidth = DetectionRecordItem(type: .boxWidth, value: 0.0)
  @Published private(set) var faceBoxHeight = DetectionRecordItem(type: .boxHeight, value: 0.0)
  
  private let videoOutputQueue = DispatchQueue(
    label: "com.intellicheck.FaceCheck.VideoOutputQueue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem
  )
  
  private let cameraFrameManager: CameraFrameManager
  private let cameraManager: CameraManager
  
  init(cameraManager: CameraManager, cameraFrameManager: CameraFrameManager) {
    self.cameraManager = cameraManager
    self.cameraFrameManager = cameraFrameManager
    
    self.cameraManager.set(videoDelegate: self.cameraFrameManager, queue: videoOutputQueue)
    self.cameraManager.set(depthDelegate: self.cameraFrameManager, queue: videoOutputQueue)
    
    setupSubscriptions()
  }
  
  func useDisparity() {
    cameraFrameManager.useDisparity(true)
  }
  
  func useDepth() {
    cameraFrameManager.useDisparity(false)
  }
  
  func switchCamera() {
    reset()
    cameraManager.switchCamera()
  }
  
  private func setupSubscriptions() {
    cameraFrameManager.$currentFrame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        CGImage.create(from: buffer)
      }
      .assign(to: &$frame)

    cameraFrameManager.$depthFrame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        CGImage.create(fromDepthDataMap: buffer)
      }
      .assign(to: &$depthFrame)
    
    cameraFrameManager.$isFaceDetected
      .receive(on: RunLoop.main)
      .assign(to: &$faceDetected)
    
    cameraFrameManager.$depth
      .receive(on: RunLoop.main)
      .assign(to: &$depth)
    
    cameraFrameManager.$faceBoxX
      .receive(on: RunLoop.main)
      .assign(to: &$faceBoxX)

    cameraFrameManager.$faceBoxY
      .receive(on: RunLoop.main)
      .assign(to: &$faceBoxY)

    cameraFrameManager.$faceBoxWidth
      .receive(on: RunLoop.main)
      .assign(to: &$faceBoxWidth)

    cameraFrameManager.$faceBoxHeight
      .receive(on: RunLoop.main)
      .assign(to: &$faceBoxHeight)

    cameraManager.$error
      .receive(on: RunLoop.main)
      .map { $0 }
      .assign(to: &$error)
  }
  
  private func reset() {
    faceDetected = false
    depth = DetectionRecordItem(type: .depth, value: 0.0)
    faceBoxX = DetectionRecordItem(type: .boxX, value: 0.0)
    faceBoxY = DetectionRecordItem(type: .boxY, value: 0.0)
    faceBoxWidth = DetectionRecordItem(type: .boxWidth, value: 0.0)
    faceBoxHeight = DetectionRecordItem(type: .boxHeight, value: 0.0)
  }
}
