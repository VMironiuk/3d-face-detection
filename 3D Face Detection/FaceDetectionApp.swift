//
//  FaceDetectionApp.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 24.08.2024.
//

import SwiftUI

@main
struct FaceDetectionApp: App {
  var body: some Scene {
    WindowGroup {
      ContentViewComposer.contentView
    }
  }
}

private enum ContentViewComposer {
  static var contentView: some View {
    ContentView(
      viewModel: ContentViewModel(
        cameraManager: CameraManager(),
        cameraFrameManager: FrameManager()
      )
    )
  }
}
