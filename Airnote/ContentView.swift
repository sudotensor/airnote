//
//  ContentView.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import RealityKit

struct ContentView : View {
  @ObservedObject var document: AirNoteDocument
  @StateObject var arController = ARController()
  
  @State private var showSheet = false
  @State private var microphoneEnabled = false
  
  var body: some View {
    ZStack {
      ARControllerWrapper(controller: arController).edgesIgnoringSafeArea(.all)
      VStack {
        Text(arController.model.mapStatusLabel).padding()
        Text(arController.model.sessionInfoLabel).padding()
        if document.transcriptText.count != 0 {
          VStack {
            Text(document.transcriptText).padding()
          }
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
          .padding(8)
        }
        Spacer()
        VStack {
          Button(action: {
            if !microphoneEnabled {
              microphoneEnabled = true
              do {
                try document.startAnalyseData()
              } catch {
                print(error)
              }
            }
            else {
              microphoneEnabled = false
              document.stopAnalyseData()
            }
          }) {
            VStack {
              Image(systemName: microphoneEnabled ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 20))
            }
            .frame(minWidth: 0, maxWidth: 50, minHeight: 0, maxHeight: 50)
            .background(microphoneEnabled ? .blue : .red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding([.top, .leading, .trailing], 16)
            .padding(.bottom, 8)
          }
          
          Button(action: {
            if microphoneEnabled {
              document.stopAnalyseData()
            }
            self.showSheet = true
          }) {
            HStack {
              Image(systemName: "note.text.badge.plus")
                .font(.system(size: 20))
              
              Text("Add Note")
                .font(.headline)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding([.top, .leading, .trailing], 16)
            .padding(.bottom, 8)
          }
          .sheet(isPresented: $showSheet, onDismiss: {
            document.clearTranscript()
            do {
              if (microphoneEnabled) {
                try document.startAnalyseData()
              }
            } catch {
              print(error)
            }
          }) {
            NoteSheet(showSheet: $showSheet, arController: arController, document: document)
          }
        }
      }
    }
  }
}
