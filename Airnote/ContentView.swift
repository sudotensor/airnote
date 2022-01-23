//
//  ContentView.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import RealityKit

struct ContentView : View {
  @State private var showSheet = false
  @State private var showTranscript = false
  @ObservedObject var document: AirNoteDocument
  
  var body: some View {
    ZStack {
      ARViewContainer().edgesIgnoringSafeArea(.all)
      VStack {
        Text(document.transcriptText).padding()
        Spacer()
        VStack {
          Button(action: {
            if !showTranscript {
              showTranscript = true
              do {
                try document.startAnalyseData()
              } catch {
                print(error)
              }
            }
            else {
              showTranscript = false
              document.stopAnalyseData()
            }
          }) {
            VStack {
              Image(systemName: showTranscript ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 20))
            }
            .frame(minWidth: 0, maxWidth: 50, minHeight: 0, maxHeight: 50)
            .background(showTranscript ? .blue : .red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding([.top, .leading, .trailing], 16)
            .padding(.bottom, 8)
          }
          
          Button(action: {
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
          .sheet(isPresented: $showSheet) {
            NoteSheet(showSheet: $showSheet)
          }
        }
      }
    }
  }
}
