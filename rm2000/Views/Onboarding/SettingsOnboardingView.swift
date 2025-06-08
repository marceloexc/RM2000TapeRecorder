//
//  SettingsOnboardingView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 6/8/25.
//

import SwiftUI

struct SettingsOnboardingView: View {
    var body: some View {
      VStack {
        Text("Where should your files go?")
      }
      .frame(width: 600, height: 500)
      .background(
        RadialGradient(
          gradient: Gradient(stops: [
            .init(color: Color(hex: 0x516068), location: 0.04),
            .init(color: Color(hex: 0x00010f), location: 0.65),
          ]),
          center: .center,
          startRadius: 0,
          endRadius: 400
        )
      )
    }
}

#Preview {
    SettingsOnboardingView()
}
