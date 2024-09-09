//
//  DetectionRecordItem.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 07.09.2024.
//

import Foundation

struct DetectionRecordItem {
  enum RecordType {
    case depth
    case disparity
    case boxX
    case boxY
    case boxWidth
    case boxHeight
  }
  
  enum ValueMatching {
    case low
    case match
    case high
  }
  
  private let type: RecordType
  private let value: Float32
  
  var name: String {
    switch type {
    case .depth, .disparity: "DEPTH:"
    case .boxX: "FACE_X:"
    case .boxY: "FACE_Y"
    case .boxWidth: "FACE_W"
    case .boxHeight: "FACE_H"
    }
  }
  
  var valueString: String {
    String(format: "%.3f", value)
  }
  
  var isMatching: Bool {
    valueMatching == .match
  }
  
  var valueMatching: ValueMatching {
    switch type {
    case .depth:
      if value >= 0.45 && value <= 0.8 {
        return .match
      } else if value < 0.5 {
        return .low
      } else {
        return .high
      }
    case .disparity:
      if value >= 1.5 && value <= 2.0 {
        return .match
      } else if value < 1.5 {
        return .low
      } else {
        return .high
      }
    case .boxX:
      if value >= 0.15 && value <= 0.35 {
        return .match
      } else if value < 0.2 {
        return .low
      } else {
        return .high
      }
    case .boxY:
      if value >= 0.25 && value <= 0.45 {
        return .match
      } else if value < 0.3 {
        return .low
      } else {
        return .high
      }
    case .boxWidth:
      if value >= 0.175 && value <= 0.35 {
        return .match
      } else if value < 0.175 {
        return .low
      } else {
        return .high
      }
    case .boxHeight:
      if value >= 0.35 && value <= 0.55 {
        return .match
      } else if value < 0.35 {
        return .low
      } else {
        return .high
      }
    }
  }
  
  init(type: RecordType, value: Float32) {
    self.type = type
    self.value = value
  }
}
