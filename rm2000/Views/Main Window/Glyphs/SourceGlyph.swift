//
//  SourceGlyph.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/19/25.
//

import SwiftUI

struct SourceGlyph: View {
    var body: some View {
			Image(systemName: "desktopcomputer")
				.fontWeight(.black)
				.foregroundColor(.black.opacity(0.35))
    }
}

#Preview {
    SourceGlyph()
}
