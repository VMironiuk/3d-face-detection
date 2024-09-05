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
  
  var body: some View {
    VStack {
      HStack {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
          VStack {
            VStack(spacing: 12) {
              RecordView(title: "INNER_DEPTH:", value: innerDepth)
              RecordView(title: "OUTER_DEPTH:", value: outerDepth)
              RecordView(title: "DEPTH_DIFF:", value: depthDiff)
            }
          }
        }
        .frame(width: 120, height: 170)
        .padding(8)
        Spacer()
      }
      Spacer()
    }
  }
}

private struct RecordView: View {
  var title: String
  var value: Float32
  var body: some View {
    VStack {
      HStack {
        Text(title)
          .font(.caption)
        Spacer()
      }
      HStack {
        Spacer()
        Text("\(value)")
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
    depthDiff: 1.234566
  )
}
