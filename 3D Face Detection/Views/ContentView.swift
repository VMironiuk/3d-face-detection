//
//  ContentView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = ContentViewModel()
  @State private var useDisparity = false
  
  var body: some View {
    ZStack {
      FrameView(image: viewModel.frame)
        .ignoresSafeArea()
      
      DepthInfoView(
        innerDepth: viewModel.innerDepth,
        outerDepth: viewModel.outerDepth,
        depthDiff: viewModel.depthDiff,
        image: viewModel.depthFrame
      )
      
      FaceDetectionView(isFaceDetected: viewModel.faceDetected)

      ErrorView(error: viewModel.error)
      
      VStack {
        Spacer()
        HStack {
          Toggle(isOn: $useDisparity) {
            Text("Disparity:")
              .foregroundStyle(.teal)
              .font(.title2)
              .bold()
          }
          .frame(width: 160)
          .padding(20)
          
          Spacer()
        }
      }
    }
    .onChange(of: useDisparity) {
      if useDisparity {
        viewModel.useDisparity()
      } else {
        viewModel.useDepth()
      }
    }
  }
}

#Preview {
  ContentView()
}
