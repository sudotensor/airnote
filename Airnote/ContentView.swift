//
//  ContentView.swift
//  Airnote
//
//  Created by Sudarshan Sreeram on 22/01/2022.
//

import SwiftUI
import RealityKit

struct ContentView : View {
  @State private var isShowingViewer = false
  
  var body: some View {
    ZStack {
      if isShowingViewer {
        ARViewContainer().edgesIgnoringSafeArea(.all)
      }
      VStack {
        Spacer()
        Button("Tap to toggle viewer") {
          isShowingViewer = !isShowingViewer
        }
        .padding()
        .background(.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
      }
    }
  }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif
