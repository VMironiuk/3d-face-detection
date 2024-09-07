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
  @Published private(set) var innerDepth: Float32 = 0.0
  @Published private(set) var outerDepth: Float32 = 0.0
  @Published private(set) var depthDiff: Float32 = 0.0
  @Published private(set) var faceBoxX: CGFloat = 0.0
  @Published private(set) var faceBoxY: CGFloat = 0.0
  @Published private(set) var faceBoxWidth: CGFloat = 0.0
  @Published private(set) var faceBoxHeight: CGFloat = 0.0
  
  private let frameManager = FrameManager.shared
  private let cameraManager = CameraManager.shared
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    setupSubscriptions()
  }
  
  func useDisparity() {
    frameManager.useDisparity(true)
  }
  
  func useDepth() {
    frameManager.useDisparity(false)
  }
  
  private func setupSubscriptions() {
    frameManager.$currentFrame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        CGImage.create(from: buffer)
      }
      .assign(to: \.frame, on: self)
      .store(in: &cancellables)

    frameManager.$depthFrame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        CGImage.create(fromDepthDataMap: buffer)
      }
      .assign(to: \.depthFrame, on: self)
      .store(in: &cancellables)
    
    frameManager.$isFaceDetected
      .receive(on: RunLoop.main)
      .assign(to: \.faceDetected, on: self)
      .store(in: &cancellables)
    
    frameManager.$innerDepth
      .receive(on: RunLoop.main)
      .assign(to: \.innerDepth, on: self)
      .store(in: &cancellables)
    
    frameManager.$outerDepth
      .receive(on: RunLoop.main)
      .assign(to: \.outerDepth, on: self)
      .store(in: &cancellables)

    frameManager.$depthDiff
      .receive(on: RunLoop.main)
      .assign(to: \.depthDiff, on: self)
      .store(in: &cancellables)
    
    frameManager.$faceBoxX
      .receive(on: RunLoop.main)
      .assign(to: \.faceBoxX, on: self)
      .store(in: &cancellables)

    frameManager.$faceBoxY
      .receive(on: RunLoop.main)
      .assign(to: \.faceBoxY, on: self)
      .store(in: &cancellables)

    frameManager.$faceBoxWidth
      .receive(on: RunLoop.main)
      .assign(to: \.faceBoxWidth, on: self)
      .store(in: &cancellables)

    frameManager.$faceBoxHeight
      .receive(on: RunLoop.main)
      .assign(to: \.faceBoxHeight, on: self)
      .store(in: &cancellables)

    cameraManager.$error
      .receive(on: RunLoop.main)
      .map { $0 }
      .assign(to: \.error, on: self)
      .store(in: &cancellables)
  }
}
