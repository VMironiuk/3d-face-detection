//
//  ContentView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = ContentViewModel()
  @State private var pixelFormat: PixelFormat = .depth
  
  var body: some View {
    ZStack {
      FrameView(image: viewModel.frame)
        .ignoresSafeArea()
      
      DetectionInfoView(
        pixelFormat: $pixelFormat,
        depth: viewModel.depth,
        faceBoxX: viewModel.faceBoxX,
        faceBoxY: viewModel.faceBoxY,
        faceBoxWidth: viewModel.faceBoxWidth,
        faceBoxHeight: viewModel.faceBoxHeight,
        image: viewModel.depthFrame
      )
      
      FaceDetectionView(isFaceDetected: viewModel.faceDetected)

      ErrorView(error: viewModel.error)
    }
    .onChange(of: pixelFormat) {
      switch pixelFormat {
      case .depth:
        viewModel.useDepth()
      case .disparity:
        viewModel.useDisparity()
      }
    }
  }
}

#Preview {
  ContentView()
}
