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
          HStack {
            ForEach(Array(sample.tags), id: \.self) { tagName in
              TagComponent(string: tagName)
            }
          }
        } else {
          Text("")
        }
      }
      .customizationID("tags")
      
      TableColumn("Kind", value: \.file.fileURL.pathExtension) { itemModel in
        Text(itemModel.file.fileURL.pathExtension.uppercased())
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
      }
        .customizationID("kind")
        .defaultVisibility(.hidden)
      
      TableColumn("Name", value: \.file.fileURL.lastPathComponent)
        .defaultVisibility(.hidden)
        .customizationID("filename")
      
      TableColumn("Date", value:\.file.fileURL.creation!) { itemModel in
        Text(itemModel.file.fileURL.creation!.formatted(date: .abbreviated, time: .shortened))
          .foregroundColor(.secondary)
      }
      .customizationID("date")
      
      TableColumn("Size", value:\.file.fileURL.fileSize) {itemModel in
        Text(itemModel.file.fileURL.fileSizeString)
          .foregroundColor(.secondary)
      }
      .customizationID("id")
      
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
            let urls = viewModel.selectedSamples.map { $0.fileURL }

            Button(urls.count == 1 ? "Open" : "Open \(urls.count) files") {
              ContextMenu.openInDefaultApp(urls: urls)
            }
            Button("Copy to Clipboard") {
              ContextMenu.copyToClipboard(urls: urls)
            }
            Button("Show in Enclosing Folder") {
              ContextMenu.revealFinder(urls: urls)
            }
            
            Divider()
            
            Button("Move to Trash") {
              ContextMenu.moveToTrash(urls: urls)
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
