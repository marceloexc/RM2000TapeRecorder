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
  @Binding var isPaused: Bool
	
	var configuration: Waveform.Configuration = Waveform.Configuration(
		style: .striped(Waveform.Style.StripeConfig(color: .white.withAlphaComponent(0.6), width: 2, spacing: 1, lineCap: .butt)),
		verticalScalingFactor: 1.0
	)
  
  private var randomID: String {
    return UUID.init().uuidString
  }
  
  init(fileURL: URL) {
    self.fileURL = fileURL
    self._isPaused = .constant(false)
  }
  
  init(fileURL: URL, isPaused: Binding<Bool>) {
    self.fileURL = fileURL
    self._isPaused = isPaused
  }
	
	var body: some View {
    Group {
      if isPaused {
        ProgressView().progressViewStyle(.circular).controlSize(.small)
          .contentTransition(.opacity)
      } else {
        WaveformView(audioURL: fileURL, configuration: .init(
          style: .striped(.init(color: .gray, width: 2, spacing: 1, lineCap: .butt)),
          verticalScalingFactor: 1)) {
            ProgressView()
              .controlSize(.extraLarge)
              .progressViewStyle(.linear)
          }
          .id(randomID) // destroy the old view manually
      }
    }
    .animation(.easeInOut(duration: 0.2), value: isPaused)
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
