//
//  WaveformView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/4/25.
//

import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct StaticWaveformView: View {
  var fileURL: URL

  @State private var isDebouncing = false
  @State private var debounceTask: DispatchWorkItem?
  @State private var hasSetInitialSize = false
  @State private var lastSize: CGSize = .zero

  var body: some View {
    ZStack {
      if isDebouncing {
        ProgressView().progressViewStyle(.circular).controlSize(.small)
      } else {
        WaveformView(
          audioURL: fileURL,
          configuration: .init(
            style: .striped(
              .init(color: .systemGray, width: 2, spacing: 1, lineCap: .round)),
            verticalScalingFactor: 0.85
          )
        ) {
          ProgressView()
            .controlSize(.extraLarge)
            .progressViewStyle(.linear)
        }
        .id(UUID.init().uuidString) // force destroy when not in view
      }
    }
    .transition(.opacity)
    .animation(.easeInOut)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      guard newSize.width > 0 && newSize.height > 0 else { return }

      if !hasSetInitialSize {
        hasSetInitialSize = true
        lastSize = newSize
        return
      }

      guard newSize != lastSize else { return }
      lastSize = newSize

      debounceSizeChange()
    }
  }

  private func debounceSizeChange() {
    debounceTask?.cancel()
    isDebouncing = true

    let task = DispatchWorkItem {
      isDebouncing = false
    }
    debounceTask = task
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
  }
}

#Preview("Waveform") {
  let fileURL = URL(
    fileURLWithPath:
      "/Users/marceloexc/Music/MusicProd/rm_testing/jazz--ambient_sample.mp3")
  StaticWaveformView(fileURL: fileURL)
}

#Preview("Library") {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
    .frame(width: 900)
}
