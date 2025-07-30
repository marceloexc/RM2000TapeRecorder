import SwiftUI

struct RecordingsTableView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel
  let predicate: SampleFilterPredicate

  @SceneStorage("SampleLibraryTableConfig")
  private var columnCustomization: TableColumnCustomization<FileRepresentableItemModel>
    
  private var sortedFilteredSamples: [FileRepresentableItemModel] {
    let filtered: [FileRepresentableItemModel]
    
    switch predicate {
    case .all:
      filtered = viewModel.filteredSamples.map { FileRepresentableItemModel(file: $0) }
    case .tagged(let tagName):
      filtered = viewModel.samples
        .filter { $0.tags.contains(tagName) }
        .map { FileRepresentableItemModel(file: $0) }
    case .untagged:
      filtered = viewModel.samples
        .filter { $0.tags.isEmpty }
        .map { FileRepresentableItemModel(file: $0) }
    }
    
    return filtered.sorted(using: sortOrder)
  }
  
  @State private var sortOrder = [
    KeyPathComparator(\FileRepresentableItemModel.text)
  ]
  
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
      
      TableColumn("Kind", value: \.file.fileURL.pathExtension)
        .customizationID("kind")
      
      TableColumn("Name", value: \.file.fileURL.lastPathComponent)
        .defaultVisibility(.hidden)
        .customizationID("filename")
      
      TableColumn("Waveform") { itemModel in
        StaticWaveformView(fileURL: itemModel.file.fileURL)
      }
      .customizationID("waveform")
      .disabledCustomizationBehavior(.resize)
    } rows: {
      ForEach(sortedFilteredSamples) { itemModel in
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
    } else {
      ProgressView("Loading recordings...")
    }
  }
}

#Preview {
  RecordingsTableView(viewModel: SampleLibraryViewModel(), predicate: .all)
    .frame(width:600, height: 700)
}
