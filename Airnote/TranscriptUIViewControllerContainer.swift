//
//  TranscriptShower.swift
//  Airnote
//
//  Created by Vincent Liu on 22/01/2022.
//

import Foundation
import SwiftUI


struct TranscriptUIViewControllerContainer: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> TranscriptViewController {
    return TranscriptViewController()
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
  }
  
  
}
