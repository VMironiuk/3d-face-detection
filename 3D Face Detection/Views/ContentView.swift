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
    FrameView(image: viewModel.frame)
      .ignoresSafeArea()
  }
}

#Preview {
  ContentView()
}
