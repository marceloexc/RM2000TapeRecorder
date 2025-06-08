//
//  WaveformView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/4/25.
//

import SwiftUI
import DSWaveformImage
import DSWaveformImageViews

struct StaticWaveformView: View {
	
	var fileURL: URL
	
	var configuration: Waveform.Configuration = Waveform.Configuration(
		style: .striped(Waveform.Style.StripeConfig(color: .white.withAlphaComponent(0.6), width: 2, spacing: 1, lineCap: .butt)),
		verticalScalingFactor: 1.0
	)
	
	var body: some View {
		WaveformView(audioURL: fileURL, configuration: .init(
      style: .striped(.init(color: .gray, width: 2, spacing: 1, lineCap: .butt)),
      verticalScalingFactor: 1)) {
			ProgressView()
				.controlSize(.extraLarge)
				.progressViewStyle(.linear)
		}
		
		
	}
}

#Preview("Waveform") {
	let fileURL = URL(fileURLWithPath: "/Users/marceloexc/Music/MusicProd/rm_testing/jazz--ambient_sample.mp3")
	StaticWaveformView(fileURL: fileURL)
}

#Preview("Library") {
	SampleLibraryView()
		.environmentObject(SampleStorage.shared)
		.frame(width: 900)
}
