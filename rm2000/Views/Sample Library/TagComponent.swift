//
//  TagComponent.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/4/25.
//

import SwiftUI

struct TagComponent: View {
	var tagName: String
	
    var body: some View {
			Text(tagName)
				.font(.caption)
				.padding(2)
				.background(Color.gray.opacity(0.2))
				.cornerRadius(3)
		}
	
}
