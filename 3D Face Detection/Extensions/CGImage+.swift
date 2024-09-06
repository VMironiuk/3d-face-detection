//
//  CGImage+.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import CoreGraphics
import CoreImage
import VideoToolbox

extension CGImage {
  static func create(from cvPixelBuffer: CVPixelBuffer?) -> CGImage? {
    guard let cvPixelBuffer else {
      return nil
    }

    var image: CGImage?
    VTCreateCGImageFromCVPixelBuffer(
      cvPixelBuffer,
      options: nil,
      imageOut: &image)
    
    return image
  }
  
  static func create(fromDepthDataMap depthDataMap: CVPixelBuffer?) -> CGImage? {
    guard let depthDataMap else {
      return nil
    }
    
    let depthCIImage = CIImage(cvPixelBuffer: depthDataMap)
      .transformed(by: CGAffineTransform(rotationAngle: -(90.0 * Double.pi / 180.0)))

    return CIContext().createCGImage(depthCIImage, from: depthCIImage.extent)
  }
}
