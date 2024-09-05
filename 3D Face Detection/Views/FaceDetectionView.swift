//
//  FaceDetectionView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 26.08.2024.
//

import SwiftUI

struct FaceDetectionView: View {
  @State private var viewSize: CGSize = .zero
  var isFaceDetected: Bool
  var body: some View {
    GeometryReader { context in
      VStack {
        RoundedRectangle(cornerRadius: frameRadius)
          .stroke(lineWidth: frameLineWidth)
          .frame(width: frameWidth, height: frameHeight)
          .foregroundStyle(isFaceDetected ? .green : .red)
          .padding()
      }
      .frame(width: context.size.width, height: context.size.height)
      .onAppear { viewSize = context.size }
    }
  }
}

private extension FaceDetectionView {
  private var frameLineWidth: CGFloat { 3 }
  private var frameRadius: CGFloat { frameWidth * 1.45 }
  private var frameHeight: CGFloat { frameWidth * 1.36 }
  private var frameWidth: CGFloat {
    switch UIDevice.current.userInterfaceIdiom {
    case .phone: min(viewSize.width, viewSize.height) / 1.8
    case .pad: min(viewSize.width, viewSize.height) / 1.93
    default: 208
    }
  }
}

#Preview {
  FaceDetectionView(isFaceDetected: false)
}
