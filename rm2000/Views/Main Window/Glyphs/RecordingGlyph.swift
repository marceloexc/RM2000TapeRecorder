//
//  RecordingGlyph.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/19/25.
//

import SwiftUI

struct RecordingGlyph: View {
    var body: some View {
			Image(systemName: "recordingtape")
				.rotationEffect(.degrees(180))
				.fontWeight(.black)
				.foregroundColor(Color("LCDTextColor").opacity(0.25))
    }
}

#Preview {
    RecordingGlyph()
}
