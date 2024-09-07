//
//  DetectionInfoView.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 05.09.2024.
//

import SwiftUI

struct DetectionInfoView: View {
  var depth: DetectionRecordItem
  var faceBoxX: DetectionRecordItem
  var faceBoxY: DetectionRecordItem
  var faceBoxWidth: DetectionRecordItem
  var faceBoxHeight: DetectionRecordItem
  var image: CGImage?
  
  var body: some View {
    VStack {
      HStack(alignment: .top) {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
          VStack {
            VStack(spacing: 2) {
              RecordView(item: depth)
              RecordView(item: faceBoxX)
              RecordView(item: faceBoxY)
              RecordView(item: faceBoxWidth)
              RecordView(item: faceBoxHeight)
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
  var item: DetectionRecordItem
  var body: some View {
    HStack {
      Text(item.name)
        .font(.caption)
      Spacer()
      Text(item.valueString)
        .foregroundStyle(item.color)
    }
    .padding(.horizontal, 4)
    .fontWeight(.semibold)
    .foregroundStyle(.teal)
  }
}

#Preview {
  DetectionInfoView(
    depth: DetectionRecordItem(type: .depth, value: 1.23456),
    faceBoxX: DetectionRecordItem(type: .boxX, value: 1.23456),
    faceBoxY: DetectionRecordItem(type: .boxY, value: 1.23456),
    faceBoxWidth: DetectionRecordItem(type: .boxWidth, value: 1.23456),
    faceBoxHeight: DetectionRecordItem(type: .boxHeight, value: 1.23456)
  )
}

private extension DetectionRecordItem {
  var color: Color {
    switch valueMatching {
    case .low: .yellow
    case .match: .green
    case .high: .red
    }
  }
}
