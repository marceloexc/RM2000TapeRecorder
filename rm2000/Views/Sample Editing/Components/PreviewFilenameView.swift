//
//  PreviewFilenameView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/3/25.
//

import SwiftUI


struct PreviewFilenameView<Model: FileRepresentable>: View {
	@ObservedObject var viewModel: EditSampleViewModel<Model>
	
	var body: some View {
		Text(viewModel.generatePreviewFilename())
			.font(.system(size: 12, weight: .regular, design: .monospaced))
			.foregroundColor(Color(red: 1, green: 0.6, blue: 0))
			.padding(4)
			.frame(maxWidth: .infinity)
			.background(Color.black)
			.contentTransition(.numericText())
			.animation(.easeInOut, value: viewModel.title)
			.animation(.easeInOut, value: viewModel.tags)
	}
}
