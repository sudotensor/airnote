//
//  AirNoteModel.swift
//  Airnote
//
//  Created by Vincent Liu on 22/01/2022.
//

import Foundation

struct AirNoteModel {
  
  var transcript: String
  
  mutating func addText(_ text: String) {
    transcript.append(contentsOf: text)
  }
  
  init() {
    transcript = "init test"
    
  }
  
}
