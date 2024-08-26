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

  @Published var current: CVPixelBuffer?
  
  @Published var faceDetected: Bool = false
  
  let videoOutputQueue = DispatchQueue(
    label: "com.vmyroniuk.VideoOutputQueue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem
  )
  
  private override init() {
    super.init()
    CameraManager.shared.set(self, queue: videoOutputQueue)
  }
  
  private func detectedFace(request: VNRequest, error: Error?) {
    if let results = request.results as? [VNFaceObservation] {
      faceDetected = true
    } else if let error {
      faceDetected = false
      print("FACE::DETECTION_ERROR: \(error.localizedDescription)")
    } else {
      faceDetected = false
    }
  }
}

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    if let buffer = sampleBuffer.imageBuffer {
      DispatchQueue.main.async {
        self.current = buffer
      }
    }
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
    let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)
    
    do {
      try sequenceHandler.perform(
        [detectFaceRequest],
        on: imageBuffer,
        orientation: .leftMirrored)
    } catch {
      print(error.localizedDescription)
    }
  }
}
