//
//  ARViewContainer.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import UIKit
import SceneKit
import RealityKit
import ARKit
import MultipeerConnectivity

struct ARModel {
  var mapButtonEnabled = false
  var mapStatusLabel = ""
  var sessionInfoLabel = ""
}

class DataModel: NSObject, NSCoding {
  var text: String!
  var colour: NoteColour!
  
  convenience init(text: String, colour: NoteColour) {
    self.init()
    self.text = text
    self.colour = colour
  }
  
  required convenience init?(coder aDecoder: NSCoder) {
    self.init()
    self.text = aDecoder.decodeObject(forKey: "text") as? String
    self.colour = NoteColour(rawValue: (aDecoder.decodeObject(forKey: "colour") as! String)) ?? .yellow
  }
  
  func encode(with aCoder: NSCoder) {
    if let text = text {
      aCoder.encode(text, forKey: "text")
    }
    print(">>>>>>>>>> Here")
    if let colour = colour {
      aCoder.encode(colour.rawValue, forKey: "colour")
    }
  }
}

class ARController: UIViewController, ARSessionDelegate, ObservableObject {
  @Published private(set) var model: ARModel
  
  var multipeerSession: MultipeerSession!
  var mapProvider: MCPeerID?
  var sceneView: ARView {
    return self.view as! ARView
  }
  
  init() {
    model = ARModel()
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    self.view = ARView(frame: .zero)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.session.delegate = self
    multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
  }
  
  func receivedData(_ data: Data, from peer: MCPeerID) {
    print(">>>>>> RECEIVED DATA <<<<<<")
    do {
      if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
        // Run the session with the received world map.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Remember who provided the map for showing UI feedback.
        mapProvider = peer
      }
      else
        if let dataModel = try NSKeyedUnarchiver.unarchivedObject(ofClass: DataModel.self, from: data) {
          // Add anchor to the session, ARSCNView delegate adds visible content.
          addNoteEntity(text: dataModel.text, colour: dataModel.colour, share: false)
        }
      else {
        print("unknown data recieved from \(peer)")
      }
    } catch {
      print("can't decode data recieved from \(peer)")
    }
  }
  
  func sendAnchorToPeers(anchor: ARAnchor) {
    guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
    else { fatalError("Can't encode anchor") }
    self.multipeerSession.sendToAllPeers(data)
  }
  
  func shareSession() {
    sceneView.session.getCurrentWorldMap { worldMap, error in
      guard let map = worldMap
      else { print("Error: \(error!.localizedDescription)"); return }
      guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
      else { fatalError("Can't encode map") }
      self.multipeerSession.sendToAllPeers(data)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    guard ARWorldTrackingConfiguration.isSupported else {
      fatalError("""
              ARKit is not available on this device. For apps that require ARKit
              for core functionality, use the `arkit` key in the key in the
              `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
              the app from installing. (If the app can't be installed, this error
              can't be triggered in a production scenario.)
              In apps where AR is an additive feature, use `isSupported` to
              determine whether to show UI for launching AR experiences.
          """) /* For details, see https://developer.apple.com/documentation/arkit */
    }
    
    /* Start the view's AR session. */
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
    
    /* Set a delegate to track the number of plane anchors for providing UI feedback. */
    sceneView.session.delegate = self
    
    sceneView.debugOptions = [ARView.DebugOptions.showFeaturePoints]
    /* Prevent the screen from being dimmed after a while as users will likely
     have long periods of interaction without touching the screen or buttons. */
    UIApplication.shared.isIdleTimerDisabled = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    /* Pause the view's AR session. */
    sceneView.session.pause()
  }
  
  // MARK: - ARSessionDelegate
  
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
  }
  
  /// - Tag: CheckMappingStatus
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    switch frame.worldMappingStatus {
    case .notAvailable, .limited:
      model.mapButtonEnabled = false
    case .extending:
      model.mapButtonEnabled = !multipeerSession.connectedPeers.isEmpty
    case .mapped:
      model.mapButtonEnabled = !multipeerSession.connectedPeers.isEmpty
    @unknown default:
      model.mapButtonEnabled = false
    }
    model.mapStatusLabel = frame.worldMappingStatus.description
    updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
  }
  
  // MARK: - ARSessionObserver
  
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay.
    model.sessionInfoLabel = "Session was interrupted"
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required.
    model.sessionInfoLabel = "Session interruption ended"
  }
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    model.sessionInfoLabel = "Session failed: \(error.localizedDescription)"
    guard error is ARError else { return }
    
    let errorWithInfo = error as NSError
    let messages = [
      errorWithInfo.localizedDescription,
      errorWithInfo.localizedFailureReason,
      errorWithInfo.localizedRecoverySuggestion
    ]
    
    // Remove optional error messages.
    let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
    
    DispatchQueue.main.async {
      // Present an alert informing about the error that has occurred.
      let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
      let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
        alertController.dismiss(animated: true, completion: nil)
        self.resetTracking()
      }
      alertController.addAction(restartAction)
      self.present(alertController, animated: true, completion: nil)
    }
  }
  
  private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
    // Update the UI to provide feedback on the state of the AR experience.
    let message: String
    
    switch trackingState {
    case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
      // No planes detected; provide instructions for this app's AR interactions.
      message = "Move around to map the environment, or wait to join a shared session."
      
    case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
      let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
      message = "Connected with \(peerNames)."
      
    case .notAvailable:
      message = "Tracking unavailable."
      
    case .limited(.excessiveMotion):
      message = "Tracking limited - Move the device more slowly."
      
    case .limited(.insufficientFeatures):
      message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
      
    case .limited(.initializing) where mapProvider != nil,
        .limited(.relocalizing) where mapProvider != nil:
      message = "Received map from \(mapProvider!.displayName)."
      
    case .limited(.relocalizing):
      message = "Resuming session — move to where you were when the session was interrupted."
      
    case .limited(.initializing):
      message = "Initializing AR session."
      
    default:
      // No feedback needed when tracking is normal and planes are visible.
      // (Nor when in unreachable limited-tracking states.)
      message = ""
      
    }
    
    model.sessionInfoLabel = message
  }
  
  func createNoteEntity(text: String, colour: NoteColour, anchor: ARAnchor) -> AnchorEntity {
    let noteAnchor: Entity & HasAnchoring = {
      switch colour {
      case .yellow: return try! Experience.loadYellow()
      case .green: return try! Experience.loadGreen()
      case .pink: return try! Experience.loadPink()
      }
    }()
    
    let paperEntity = noteAnchor.findEntity(named: "Plane")! as! ModelEntity
    
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
    
    let anchorEntity = AnchorEntity(anchor: anchor)
    anchorEntity.addChild(noteAnchor)
    
    return anchorEntity
  }
  
  func addNoteEntity(text: String, colour: NoteColour, share: Bool = true) {
    var viewCenter: CGPoint {
      let viewBounds = view.bounds
      return CGPoint(x: viewBounds.width / 2.0, y: viewBounds.height / 2.0)
    }
    
    if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
      let anchor = ARAnchor.init(transform: hit.worldTransform)
      let noteEntity: AnchorEntity = createNoteEntity(text: text, colour: colour, anchor: anchor)
      sceneView.scene.anchors.append(noteEntity)
      self.sceneView.installGestures(for: noteEntity.findEntity(named: "paper")! as! Entity & HasCollision)
      sceneView.session.add(anchor: anchor)

      if share {
        let dataModel = DataModel(text: text, colour: colour)
        let data = NSKeyedArchiver.archivedData(withRootObject: dataModel)
        self.multipeerSession.sendToAllPeers(data)
        shareSession()
        // Send the anchor info to peers, so they can place the same content.
      }
    }
  }
  
  /* Reset Tracking for Scene */
  func resetTracking() {
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
  }
}

struct ARControllerWrapper: UIViewControllerRepresentable {
  typealias UIViewControllerType = ARController
  @State var controller: ARController = ARController()
  
  func makeUIViewController(context: Context) -> ARController {
    return controller
  }
  
  func updateUIViewController(_ uiViewController: ARControllerWrapper.UIViewControllerType, context: Context) { /* Nothing to do here */ }
}
