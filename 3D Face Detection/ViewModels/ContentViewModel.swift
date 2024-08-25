//
//  ContentViewModel.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import CoreImage
import Combine

final class ContentViewModel: ObservableObject {
  @Published var frame: CGImage?
  @Published var error: Error?
  
  private let frameManager = FrameManager.shared
  private let cameraManager = CameraManager.shared
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    setupSubscriptions()
  }
  
  func setupSubscriptions() {
    frameManager.$current
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        CGImage.create(from: buffer)
      }
      .assign(to: \.frame, on: self)
      .store(in: &cancellables)
    
    cameraManager.$error
      .receive(on: RunLoop.main)
      .map { $0 }
      .assign(to: \.error, on: self)
      .store(in: &cancellables)
  }
}
