//
//  RecordingGlyph.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/19/25.
//

import SwiftUI

struct RecordingGlyph: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
    var body: some View {
			if recordingState.status == .busy {
				Image(systemName: "recordingtape")
					.rotationEffect(.degrees(180))
					.fontWeight(.black)
					.foregroundColor(Color("LCDTextColor"))
					.pulseEffect()
			} else {
				Image(systemName: "recordingtape")
					.rotationEffect(.degrees(180))
					.fontWeight(.black)
					.foregroundColor(Color("LCDTextColor").opacity(0.25))
			}

    }
}

#Preview {
    RecordingGlyph()
}
