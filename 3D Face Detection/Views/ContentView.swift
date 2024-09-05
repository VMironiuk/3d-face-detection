//
//  ContentView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = ContentViewModel()
  
  var body: some View {
    ZStack {
      FrameView(image: viewModel.frame)
        .ignoresSafeArea()
      
      DepthInfoView(
        innerDepth: viewModel.innerDepth,
        outerDepth: viewModel.outerDepth,
        depthDiff: viewModel.depthDiff
      )
      
      FaceDetectionView(isFaceDetected: viewModel.faceDetected)

      ErrorView(error: viewModel.error)
    }
  }
}

#Preview {
  ContentView()
}
