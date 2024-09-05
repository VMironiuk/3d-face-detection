//
//  CameraManager.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import AVFoundation

final class CameraManager: ObservableObject {
  enum Status {
    case unconfigured
    case configured
    case unauthorized
    case failed
  }
  
  static let shared = CameraManager()
  
  @Published private(set) var error: CameraError?
  
  private let sessionQueue = DispatchQueue(label: "com.vmyroniuk.SessionQueue")
  private let session = AVCaptureSession()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let depthOutput = AVCaptureDepthDataOutput()
  private var status = Status.unconfigured
  
  private init() {
    configure()
  }
  
  func set(
    videoDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
    queue: DispatchQueue
  ) {
    videoOutput.setSampleBufferDelegate(videoDelegate, queue: queue)
  }
  
  func set(
    depthDelegate: AVCaptureDepthDataOutputDelegate,
    queue: DispatchQueue
  ) {
    depthOutput.setDelegate(depthDelegate, callbackQueue: queue)
  }
}

private extension CameraManager {
  private func configure() {
    checkPermissions()
    sessionQueue.async {
      self.configureCaptureSession()
      self.session.startRunning()
    }
  }
  
  private func configureCaptureSession() {
    guard status == .unconfigured else {
      return
    }
    session.beginConfiguration()
    defer {
      session.commitConfiguration()
    }
    
    let device = AVCaptureDevice.default(
      .builtInTrueDepthCamera,
      for: .video,
      position: .front)
    guard let camera = device else {
      set(error: .cameraUnavailable)
      status = .failed
      return
    }
    
    do {
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      if session.canAddInput(cameraInput) {
        session.addInput(cameraInput)
      } else {
        set(error: .cameraUnavailable)
        status = .failed
        return
      }
    } catch {
      set(error: .createCaptureInput(error))
      status = .failed
      return
    }
    
    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
      videoOutput.videoSettings = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
      ]
      let videoConnection = videoOutput.connection(with: .video)
      videoConnection?.videoRotationAngle = 90
    } else {
      set(error: .cannotAddOutput)
      status = .failed
      return
    }
    
    if session.canAddOutput(depthOutput) {
      session.addOutput(depthOutput)
      let depthConnection = depthOutput.connection(with: .video)
      depthConnection?.isEnabled = true
    } else {
      set(error: .cannotAddOutput)
      status = .failed
      return
    }

    status = .configured
  }
  
  private func set(error: CameraError?) {
    DispatchQueue.main.async {
      self.error = error
    }
  }
  
  private func checkPermissions() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      sessionQueue.suspend()
      AVCaptureDevice.requestAccess(for: .video) { authorized in
        if !authorized {
          self.status = .unauthorized
          self.set(error: .deniedAuthorization)
        }
        self.sessionQueue.resume()
      }
      
    case .restricted:
      status = .unauthorized
      set(error: .restrictedAuthorization)
      
    case .denied:
      status = .unauthorized
      set(error: .deniedAuthorization)
      
    case .authorized:
      break
      
    @unknown default:
      status = .unauthorized
      set(error: .unknownAuthorization)
    }
  }
}
