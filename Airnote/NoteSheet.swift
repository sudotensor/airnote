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

struct NoteSheet: View {
  @Binding var showSheet: Bool
  @State var saveDisabled: Bool = true
  var mode: SheetAction = .add
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Note Content")) {
          Text("Textfield here...")
        }
        
        Section(header: Text("Note Preferences")) {
          Text("Toggles here...")
        }
      }
      .listStyle(.insetGrouped)
      .navigationBarTitle(self.mode.rawValue, displayMode: .inline)
      .navigationBarItems(leading: Button("Cancel") {
        self.showSheet = false
      }, trailing: Button("Save") {
        /* Create and add a note to the scene or update its contents */
      }.disabled(saveDisabled))
    }
  }
}

struct NoteSheet_Previews: PreviewProvider {
  static var previews: some View {
    NoteSheet(showSheet: .constant(true))
  }
}
