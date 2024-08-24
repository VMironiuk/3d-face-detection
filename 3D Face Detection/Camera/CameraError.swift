//
//  CameraError.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import Foundation

enum CameraError: Error {
  case cameraUnavailable
  case cannotAddInput
  case cannotAddOutput
  case createCaptureInput(Error)
  case deniedAuthorization
  case restrictedAuthorization
  case unknownAuthorization
}

extension CameraError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .cameraUnavailable:
      "Camera unavailable"
    case .cannotAddInput:
      "Cannot add capture input to session"
    case .cannotAddOutput:
      "Cannot add video output to session"
    case .createCaptureInput(let error):
      "Creating capture input for camera: \(error.localizedDescription)"
    case .deniedAuthorization:
      "Camera access denied"
    case .restrictedAuthorization:
      "Attempting to access a restricted capture device"
    case .unknownAuthorization:
      "Unknown authorization status for capture device"
    }
  }
}
