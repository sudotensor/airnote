//
//  AirNoteDoc.swift
//  Airnote
//
//  Created by Vincent Liu on 22/01/2022.
//

import SwiftUI
import AVFoundation
import Starscream

class AirNoteDocument: ObservableObject, WebSocketDelegate {
  @Published private(set) var airNote: AirNoteModel
  private let key = "Token 1a93ef67fe98c59fdd4b50a973181d3a92384d84"
  
  enum RecordingState {
    case recording, paused, stopped
  }
  
  private var engine: AVAudioEngine!
  private var converterNode: AVAudioMixerNode!
  private var sinkNode: AVAudioMixerNode!
  private var state: RecordingState = .stopped
  private var isInterrupted = false
  
  private lazy var socket: WebSocket = {
    let url = URL(string: "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=48000&channels=1")!
    var request = URLRequest(url: url)
    request.setValue(key, forHTTPHeaderField: "Authorization")
    return WebSocket(request: request)
  }()
  
  
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
  
  private let transcriptView: UITextView = {
    let textView = UITextView()
    textView.isScrollEnabled = true
    textView.backgroundColor = .lightGray
    textView.translatesAutoresizingMaskIntoConstraints = false
    return textView
  }()
  
  init() {
    airNote = AirNoteModel()
    setupSession()
    setupEngine()
  }
  
  func setupSession () {
    let session = AVAudioSession.sharedInstance()
    
    do {
      try session.setCategory(.record)
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("Error: Come find me in setupSession!")
      print(error)
    }
  }
  
  var transcriptText: String {
    airNote.transcript
  }
  
  
  func setupEngine() {
    engine = AVAudioEngine()
    converterNode = AVAudioMixerNode()
    sinkNode = AVAudioMixerNode()
    
    engine.attach(converterNode)
    engine.attach(sinkNode)
    
    let inputNode = engine.inputNode
    do {
      try inputNode.setVoiceProcessingEnabled(true)
    } catch {
      print("Could not enable voice processing \(error)")
      return
    }
    
    let inputFormat = inputNode.inputFormat(forBus: 0)
    let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: inputFormat.sampleRate, channels: 1, interleaved: true)

    engine.connect(inputNode, to: converterNode, format: inputFormat)
    engine.connect(converterNode, to: sinkNode, format: outputFormat)
    
    engine.prepare()
  }

  func startAnalyseData() throws {
    socket.delegate = self
    socket.connect()
    
    converterNode.installTap(onBus: 0, bufferSize: 1024, format: converterNode.outputFormat(forBus: 0), block: { (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
      if let data = self.toNSData(buffer: buffer) {
        self.socket.write(data: data)
      }
    })
    
    try engine.start()
    state = .recording
  }
  
  func stopAnalyseData() {
    converterNode.removeTap(onBus: 0)
    socket.disconnect()
    engine.stop()
    state = .stopped
  }
  
  func pauseAnalyseData() {
    engine.pause()
    state = .paused
  }
  
  func resumeAnalyseData() throws {
    try engine.start()
    state = .recording
  }
  
  private func toNSData(buffer: AVAudioPCMBuffer) -> Data? {
    let audioBuffer = buffer.audioBufferList.pointee.mBuffers
    return Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
  }
  
  func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .text(let text):
      let jsonData = Data(text.utf8)
      let response = try! decoder.decode(DeepgramResponse.self, from: jsonData)
      let transcript = response.channel.alternatives.first!.transcript
      
      if response.isFinal && !transcript.isEmpty {
        
        addText(" " + transcript)
      }
    case .error(let error):
      print(error ?? "")
    default:
      break
    }
  }
  
  func registerForNotifications() {
    NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: nil,
      queue: nil
    )
    { [weak self] (notification) in
      guard let weakself = self else {
        return
      }

      let userInfo = notification.userInfo
      let interruptionTypeValue: UInt = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
      let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue)!

      switch interruptionType {
      case .began:
        weakself.isInterrupted = true

        if weakself.state == .recording {
          weakself.pauseAnalyseData()
        }
      case .ended:
        weakself.isInterrupted = false

        // Activate session again
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        if weakself.state == .paused {
          try? weakself.resumeAnalyseData()
        }
      @unknown default:
        break
      }
    }
  }
  
  // MARK: - Intents
  
  func addText(_ text: String) {
    // adding text every 10 sec
    airNote.addText(text)
  }
}

struct DeepgramResponse: Codable {
  let isFinal: Bool
  let channel: Channel
  
  struct Channel: Codable {
    let alternatives: [Alternatives]
  }
  
  struct Alternatives: Codable {
    let transcript: String
  }
}


