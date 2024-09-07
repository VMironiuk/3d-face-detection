//
//  DetectionInfoView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 05.09.2024.
//

import SwiftUI

struct DetectionInfoView: View {
  var innerDepth: Float32
  var faceBoxX: CGFloat
  var faceBoxY: CGFloat
  var faceBoxWidth: CGFloat
  var faceBoxHeight: CGFloat
  var image: CGImage?
  
  var body: some View {
    VStack {
      HStack(alignment: .top) {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
          VStack {
            VStack(spacing: 2) {
              RecordView(title: "DEPTH:", value: String(format: "%.3f", innerDepth))
              RecordView(title: "BOX_X:", value: String(format: "%.3f", faceBoxX))
              RecordView(title: "BOX_Y:", value: String(format: "%.3f", faceBoxY))
              RecordView(title: "BOX_W:", value: String(format: "%.3f", faceBoxWidth))
              RecordView(title: "BOX_H:", value: String(format: "%.3f", faceBoxHeight))
            }
          }
        }
        .frame(width: 120, height: 140)
        .padding(8)
        Spacer()
        FrameView(image: image)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .frame(width: 140, height: 200)
          .padding(8)
      }
      Spacer()
    }
  }
}

private struct RecordView: View {
  var title: String
  var value: String
  var body: some View {
    HStack {
      Text(title)
        .font(.caption)
      Spacer()
      Text(value)
    }
    .padding(.horizontal, 4)
    .fontWeight(.semibold)
    .foregroundStyle(.teal)
  }
}

#Preview {
  DetectionInfoView(
    innerDepth: 1.234566,
    faceBoxX: 1.234566,
    faceBoxY: 1.234566,
    faceBoxWidth: 1.234566,
    faceBoxHeight: 1.234566
  )
}
