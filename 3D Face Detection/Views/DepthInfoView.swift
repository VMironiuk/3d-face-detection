//
//  DepthInfoView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 05.09.2024.
//

import SwiftUI

struct DepthInfoView: View {
  var innerDepth: Float32
  var outerDepth: Float32
  var depthDiff: Float32
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
              RecordView(title: "INNER_DEPTH:", value: String(format: "%.3f", innerDepth))
              RecordView(title: "OUTER_DEPTH:", value: String(format: "%.3f", outerDepth))
              RecordView(title: "DEPTH_DIFF:", value: String(format: "%.3f", depthDiff))
              RecordView(title: "FACE_BOX_X:", value: String(format: "%.3f", faceBoxX))
              RecordView(title: "FACE_BOX_Y:", value: String(format: "%.3f", faceBoxY))
              RecordView(title: "FACE_VOX_W:", value: String(format: "%.3f", faceBoxWidth))
              RecordView(title: "FACE_BOX_H:", value: String(format: "%.3f", faceBoxHeight))
            }
          }
        }
        .frame(width: 120, height: 340)
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
    VStack {
      HStack {
        Text(title)
          .font(.caption)
        Spacer()
      }
      HStack {
        Spacer()
        Text(value)
      }
    }
    .padding(4)
    .fontWeight(.semibold)
    .foregroundStyle(.teal)
  }
}

#Preview {
  DepthInfoView(
    innerDepth: 1.234566,
    outerDepth: 1.234566,
    depthDiff: 1.234566,
    faceBoxX: 1.234566,
    faceBoxY: 1.234566,
    faceBoxWidth: 1.234566,
    faceBoxHeight: 1.234566
  )
}
