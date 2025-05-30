//
//  TagComponent.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/4/25.
//

import SwiftUI

struct TagComponent: View {
	var string: String?
    var body: some View {
			
			if let tag = string {
				Text(tag)
					.font(.caption)
					.padding(2)
					.background(Color.gray.opacity(0.2))
					.cornerRadius(3)
			} else {
				Text("")
					.font(.caption)
					.padding(2)
			}
			
		}
}
