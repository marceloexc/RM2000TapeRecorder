import SwiftUI

struct RecordingsTableView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel
  
  // the waveform package may crash the app when resizing because
  // it doesn't know when to stop and just recomputes the waveform
  // randomly.
  
  // this binding makes us manually stop that
  @State private var isResizing: Bool = false
  let viewType: SampleFilterPredicate
  
  private var filteredSamples: [Sample] {
    switch viewType {
    case .all:
      return viewModel.filteredSamples
    case .tagged(let tagName):
      return viewModel.samples.filter { $0.tags.contains(tagName) }
    case .untagged:
      return viewModel.samples.filter { $0.tags.isEmpty }
    }
  }
  
    var body: some View {
      Table(filteredSamples) {
        TableColumn("Name", value: \.filename!)
        TableColumn("Title", value: \.title)
        TableColumn("Tags") { sample in
          Text(sample.tags.joined(separator: ", "))
        }
        TableColumn("Waveform") { sample in
          StaticWaveformView(fileURL: sample.fileURL, isPaused: $isResizing)
            .frame(maxWidth: 200)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { notification in
        isResizing = true
      }
      .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEndLiveResizeNotification)) { notification in
        isResizing = false
      }
    }
}

#Preview {
//    RecordingsTableView()
}
