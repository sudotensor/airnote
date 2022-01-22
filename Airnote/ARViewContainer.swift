//
//  ARViewContainer.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import RealityKit

struct ARViewContainer: UIViewRepresentable {
  func makeUIView(context: Context) -> ARView {
    
    let arView = ARView(frame: .zero)
    
    // Load the "Box" scene from the "Experience" Reality File
    let boxAnchor = try! Experience.loadBox()
    
    // Add the box anchor to the scene
    arView.scene.anchors.append(boxAnchor)
    
    return arView
    
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ARViewContainer_Previews: PreviewProvider {
  static var previews: some View {
    ARViewContainer()
  }
}
