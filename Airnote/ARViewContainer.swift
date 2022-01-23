//
//  ARViewContainer.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import RealityKit
import ARKit
//import MultipeerHelper

struct ARViewContainer: UIViewRepresentable {
  @State var view: ARView = ARView(frame: .zero)
//  @State var multipeerHelp = MultipeerHelper(
//    serviceName: "airnote",
//    sessionType: .both
//  )
  
  func addNoteEntity(text: String, colour: NoteColour) {
    let noteAnchor: Entity & HasAnchoring = {
      switch colour {
      case .yellow: return try! Experience.loadYellow()
      case .green: return try! Experience.loadGreen()
      case .pink: return try! Experience.loadPink()
      }
    }()
    
    let paperEntity = noteAnchor.findEntity(named: "Plane")! as!  ModelEntity
    
    let textMesh = MeshResource.generateText(
      text,
      extrusionDepth: 0.001,
      font: .systemFont(ofSize: 0.1),
      containerFrame: .init(x: 0.0, y: 0.0, width: 1.6, height: 1.2),
      alignment: .left,
      lineBreakMode: .byWordWrapping
    )
    
    let textMaterial = SimpleMaterial(color: .black, isMetallic: false)
    
    let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
    
    textEntity.transform.rotation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) * simd_quatf(angle: .pi/2, axis: [0, 0, 1])
    textEntity.transform.translation = SIMD3<Float>(0.9, 0.035, 0.8)
            
    paperEntity.addChild(textEntity)
    
    self.view.scene.anchors.append(noteAnchor)
    
    self.view.installGestures(for: noteAnchor.findEntity(named: "paper")! as! Entity & HasCollision)
  }
  
  func makeUIView(context: Context) -> ARView {
//    self.view.scene.synchronizationService = self.multipeerHelp.syncService
//    let configuration = ARWorldTrackingConfiguration()
//    configuration.isCollaborationEnabled = true
//    configuration.environmentTexturing = .automatic
//    self.view.session.run(configuration)
    return self.view
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ARViewContainer_Previews: PreviewProvider {
  static var previews: some View {
    ARViewContainer()
  }
}
