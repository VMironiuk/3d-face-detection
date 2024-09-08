//
//  PixelFormat.swift
//  3D Face Detection
//
//  Created by Volodymyr Myroniuk on 08.09.2024.
//

import Foundation

enum PixelFormat: String, CaseIterable, Identifiable {
  case depth
  case disparity
  var id: Self { self }
}
