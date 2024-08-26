//
//  FaceDetectionView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 26.08.2024.
//

import SwiftUI

struct FaceDetectionView: View {
  var faceDetected: Bool
  
  var body: some View {
    ZStack {
      Ellipse()
        .stroke(lineWidth: 2.0)
        .foregroundStyle(faceDetected ? Color.green : Color.red)
        .frame(width: 250, height: 400)
    }
  }
}

#Preview {
  FaceDetectionView(faceDetected: false)
}
