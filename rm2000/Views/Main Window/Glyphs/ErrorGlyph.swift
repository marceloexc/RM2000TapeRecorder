//
//  ErrorGlyph.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/19/25.
//

import SwiftUI

struct ErrorGlyph: View {
    var body: some View {
			Image(systemName: "exclamationmark.triangle")
				.fontWeight(.black)
				.foregroundColor(.black.opacity(0.35))
    }
}

#Preview {
    ErrorGlyph()
}
