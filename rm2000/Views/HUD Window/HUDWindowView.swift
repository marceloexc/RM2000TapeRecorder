//
//  HUDWindowView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/26/25.
//

import SwiftUI
import FluidGradient

struct HUDWindowView: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
	@State private var isAnimating = true
    var body: some View {
			ZStack {
				
				FluidGradient(blobs: [Color(hex: 0xCA7337)],
											highlights: [ .gray],
											speed: 1.0,
											blur: 0.75)
				.background(.quaternary)
				
				LCDSymbolGlyphs()
			}
    }
}



#Preview {
    HUDWindowView()
		.environmentObject(TapeRecorderState())
}
