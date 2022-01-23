//
//  NoteSheet.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI

enum SheetAction: String {
  case add = "Add Note", edit = "Edit Note"
}

enum NoteColour: String, CodingKey {
  case yellow = "yellow", pink = "pink", green = "green"
}

struct NoteSheet: View {
  @Binding var showSheet: Bool
  
  @ObservedObject var arController: ARController
  @ObservedObject var document: AirNoteDocument
  
  @State private var noteColour: NoteColour = .yellow
  
  var size: CGFloat = 36
  var mode: SheetAction = .add
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Note Content")) {
          Text(document.transcriptText).padding(8)
        }
        
        Section(header: Text("Note Colour")) {
          HStack(spacing: 16) {
            Circle()
              .frame(width: size, height: size)
              .foregroundColor(.yellow)
              .onTapGesture {
                noteColour = .yellow
              }
              .padding(4)
              .background(noteColour == .yellow ? .yellow.opacity(0.5) : .clear)
              .cornerRadius(CGFloat(size / 2 + 4))
            Spacer()
            Circle()
              .frame(width: size, height: size)
              .foregroundColor(.pink)
              .onTapGesture {
                noteColour = .pink
              }
              .padding(4)
              .background(noteColour == .pink ? .pink.opacity(0.5) : .clear)
              .cornerRadius(CGFloat(size / 2 + 4))
            Spacer()
            Circle()
              .frame(width: size, height: size)
              .foregroundColor(.green)
              .onTapGesture {
                noteColour = .green
              }
              .padding(4)
              .background(noteColour == .green ? .green.opacity(0.5) : .clear)
              .cornerRadius(CGFloat(size / 2 + 4))
          }
          .padding(8)
        }
      }
      .listStyle(.insetGrouped)
      .navigationBarTitle(self.mode.rawValue, displayMode: .inline)
      .navigationBarItems(leading: Button("Cancel") {
        self.showSheet = false
      }, trailing: Button("Save") {
        /* Create and add a note to the scene or update its contents */
        arController.addNoteEntity(text: document.transcriptText, colour: noteColour)
        self.showSheet = false
      })
    }
  }
}
