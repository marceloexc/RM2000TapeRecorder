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
  
  @State private var sortedAndFilteredSamples: [FileRepresentableItemModel] = []
  
  private var filteredSamples: [FileRepresentableItemModel] {
    
    let tableItemsAsFileRepresentable = viewModel.filteredSamples
      .map { FileRepresentableItemModel(file: $0) }
    switch viewType {
    case .all:
      return tableItemsAsFileRepresentable
    case .tagged(let tagName):
      return viewModel.samples
        .filter { $0.tags.contains(tagName) }
        .map { FileRepresentableItemModel(file: $0) }
    case .untagged:
      return viewModel.samples
        .filter { $0.tags.isEmpty }
        .map { FileRepresentableItemModel(file: $0) }
    }
  }
  
  @State private var sortOrder = [
    KeyPathComparator(\FileRepresentableItemModel.text)
  ]
  
  @SceneStorage("SampleLibraryTableConfig")
  private var columnCustomization: TableColumnCustomization<FileRepresentableItemModel>
  
  var table: some View {
    Table(selection: $viewModel.predicateSelection, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
      TableColumn("Title", value: \.text)
        .customizationID("title")
      
      TableColumn("Tags") { itemModel in
        if let sample = itemModel.file as? Sample {
          Text(sample.tags.joined(separator: ", "))
        } else {
          Text("")
        }
      }
      .customizationID("tags")
      
      // TODO - something is wrong with sample.metadata.fileFormat
      TableColumn("Kind", value: \.file.fileURL.pathExtension)
        .customizationID("kind")
      
      TableColumn("Name", value: \.file.fileURL.lastPathComponent)
        .defaultVisibility(.hidden)
        .customizationID("filename")
      
      TableColumn("Waveform") { itemModel in
        StaticWaveformView(fileURL: itemModel.file.fileURL, isPaused: $isResizing)
      }
      .customizationID("waveform")
      .disabledCustomizationBehavior(.resize)
    } rows: {
      ForEach(sortedAndFilteredSamples) { itemModel in
        TableRow(itemModel)
          .draggable(itemModel)
          .contextMenu {
            if viewModel.selectedSamples.count > 1 {
              Button("Open \(viewModel.selectedSamples.count) files") {
                for file in viewModel.selectedSamples {
                  NSWorkspace.shared.open(file.fileURL)
                }
              }
            } else {
              Button("Open") {
                NSWorkspace.shared.open(viewModel.selectedSamples.first!.fileURL)
              }
            }
            Button("Print") {
              print(viewModel.selectedSamples)
            }
          }
      }
    }
  }
  
    
  var body: some View {
    if viewModel.finishedProcessing {
      table
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
  RecordingsTableView(viewModel: SampleLibraryViewModel(), viewType: .all)
    .frame(width:600, height: 700)
}
