import SwiftUI

struct RecordingsTableView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel
  
  // the waveform package may crash the app when resizing because
  // it doesn't know when to stop and just recomputes the waveform
  // randomly.
  
  // this binding makes us manually stop that
  @State private var isResizing: Bool = false
  @State private var firstWindowAppearance: Bool = true
  
  let viewType: SampleFilterPredicate
  
  @State private var sortedAndFilteredSamples: [Sample] = []
  
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
  
  @State private var sortOrder = [KeyPathComparator(\Sample.title)]
  @SceneStorage("SampleLibraryTableConfig")
  private var columnCustomization: TableColumnCustomization<Sample>
  
    
  var body: some View {
    if viewModel.finishedProcessing {
      Table(sortedAndFilteredSamples, selection: $viewModel.predicateSelection, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
        TableColumn("Name", value: \.filename!)
          .defaultVisibility(.hidden)
          .customizationID("filename")
        TableColumn("Title", value: \.title)
          .customizationID("title")

        TableColumn("Tags") { sample in
          Text(sample.tags.joined(separator: ", "))
        }
        .customizationID("tags")
        
        // TODO - something is wrong with sample.metadata.fileFormat
        TableColumn("Kind", value: \.fileURL.pathExtension)
          .customizationID("kind")

        TableColumn("Waveform") { sample in
          StaticWaveformView(fileURL: sample.fileURL, isPaused: $isResizing)
            .frame(maxWidth: 200)
        }
        .customizationID("waveform")
        .disabledCustomizationBehavior(.resize)
      }
      .contextMenu {
        Button("Print") {
          print(viewModel.selectedSample)
        }
      }
      .onAppear {
        sortedAndFilteredSamples = filteredSamples.sorted(using: sortOrder)
      }
      .onChange(of: sortOrder, { _, newSortOrder in
        sortedAndFilteredSamples.sort(using: newSortOrder)
      })
    } else {
      ProgressView("Loading recordings...")
    }
  }
}

#Preview {
//    RecordingsTableView()
}
