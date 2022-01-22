//
//  ContentView.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import RealityKit

struct AirNoteDocView : View {
  @State private var isShowingViewer = false
  @State private var showTranscript = false
  @ObservedObject var doc: AirNoteDoc
  
  var body: some View {
    ZStack {
      if isShowingViewer {
        ARViewContainer().edgesIgnoringSafeArea(.all)
      }
      VStack {
        Text(doc.transcriptText).padding()
        Spacer()
        HStack{
          Button("Tap to toggle viewer") {
            isShowingViewer = !isShowingViewer
          }
          .padding()
          .background(.blue)
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12.0))
          Spacer()
          Button("Start transcripting") {
            if !showTranscript {
              showTranscript = true
              doc.startAnalyseData()
            }
            else {
             showTranscript = false
             doc.stopAnalyseData()
            }
          }
        }

      }
    }
  }
}

#if DEBUG
struct AirNoteDocView_Previews : PreviewProvider {
  static var previews: some View {
    ContentView(doc: AirNoteDoc())
  }
}
#endif
