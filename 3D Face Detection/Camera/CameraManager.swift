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
  private var cameraType = CameraType.front
  
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
  
  func switchCamera() {
    cameraType = cameraType.opposite
    do {
      try setupCamera(for: cameraType)
    } catch {
      set(error: error as? CameraError)
      status = .failed
    }
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
    
    do {
      try setupCamera(for: cameraType)
    } catch {
      set(error: error as? CameraError)
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
  
  private func setupCamera(for cameraType: CameraType) throws {
    let sessionWasRunning = session.isRunning
    if sessionWasRunning { session.stopRunning() }
    session.beginConfiguration()
    
    let device = cameraType.captureDevice
    guard let camera = device else {
      throw CameraError.cameraUnavailable
    }

    session.inputs.forEach { session.removeInput($0) }
    do {
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      if session.canAddInput(cameraInput) {
        session.addInput(cameraInput)
      } else {
        throw CameraError.cameraUnavailable
      }
    } catch {
      throw CameraError.createCaptureInput(error)
    }
    
    setupConnections(for: cameraType)
    
    session.commitConfiguration()
    if sessionWasRunning { Task { session.startRunning() } }
  }
  
  private func setupConnections(for cameraType: CameraType) {
    let videoConnection = videoOutput.connection(with: .video)
    let depthConnection = depthOutput.connection(with: .video)
    
    if cameraType == .rear {
      videoConnection?.isVideoMirrored = true
      depthConnection?.isVideoMirrored = true
    }
    videoConnection?.videoRotationAngle = 90
    depthConnection?.videoRotationAngle = 90
    depthConnection?.isEnabled = true
  }
}

private extension CameraManager {
  enum CameraType {
    case front
    case rear
    
    var opposite: Self {
      switch self {
      case .front: .rear
      case .rear: .front
      }
    }
    
    var captureDevice: AVCaptureDevice? {
      switch self {
      case .front:
        AVCaptureDevice.default(
          .builtInTrueDepthCamera,
          for: .video,
          position: .front
        )
      case .rear:
        AVCaptureDevice.default(
          .builtInDualCamera,
          for: .video,
          position: .back
        )
      }
    }
  }
}
