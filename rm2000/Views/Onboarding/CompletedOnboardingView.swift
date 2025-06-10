//
//  CompletedOnboardingView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 6/9/25.
//

import SwiftUI

struct CompletedOnboardingView: View {
  
    var body: some View {
      VStack {
        Text("RM2000 Tape Recorder is now set up!")
          .font(.custom("LucidaGrande-Bold", size: 24))
          .kerning(-1.0)
        
        Text("Have fun!!!")
          .font(.custom("LucidaGrande-Bold", size: 24))
          .kerning(-1.0)
        
        Button {
          relaunch()
        } label: {
          Text("Restart")
            .controlSize(.extraLarge)
        }

      }
      .frame(width: 700, height: 550)
      .background(
        GeometryReader { geometry in
          RadialGradient(
            gradient: Gradient(stops: [
              .init(color: Color(hex: 0xc1c6c4), location: 0.04),
              .init(color: Color(hex: 0x959d9f), location: 0.16),
              .init(color: Color(hex: 0x6c757a), location: 0.28),
              .init(color: Color(hex: 0x454e56), location: 0.40),
              .init(color: Color(hex: 0x212732), location: 0.52),
              .init(color: Color(hex: 0x00010f), location: 0.65),
            ]),
            center: UnitPoint(x: 0.5, y: 0.5),
            startRadius: 0,
            endRadius: max(geometry.size.width, geometry.size.height) * 0.75
          )
          .scaleEffect(x: 1.4, y: 1)
        }
      )
    }
  
  private func relaunch(afterDelay seconds: TimeInterval = 0.5) -> Never {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
    task.launch()
    
    NSApp.terminate(self)
    exit(0)
  }
}

#Preview {
    CompletedOnboardingView()
}
