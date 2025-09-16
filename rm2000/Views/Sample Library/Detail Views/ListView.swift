import SwiftUI

struct RecordingsListView: View {
  @StateObject var viewModel: SampleLibraryViewModel
  let predicate: SampleFilterPredicate
  
  private var filteredSamples: [Sample] {
    switch predicate {
    case .all:
      return viewModel.filteredSamples
    case .tagged(let tagName):
      return viewModel.samples.filter { $0.tags.contains(tagName) }
    case .untagged:
      return viewModel.samples.filter { $0.tags.isEmpty }
    }
  }
  
  var body: some View {
    ZStack {
      if viewModel.finishedProcessing {
        List(filteredSamples, id: \.id, selection: $viewModel.predicateSelection) {
          sample in
          let itemModel = FileRepresentableItemModel(file: sample)
          SampleIndividualListItem(viewModel: viewModel, sample: itemModel)
            .tag(sample.id)
        }
      } else {
        ProgressView("Loading recordings...")
      }
    }
  }
}

struct SampleIndividualListItem: View {
  @StateObject var viewModel: SampleLibraryViewModel
  @Environment(\.openWindow) var openWindow
  var sample: FileRepresentableItemModel
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("\(sample.text)")
          .font(.title3)
        if let sampleObj = sample.file as? Sample {
          HStack(spacing: 8) {
            if !sampleObj.tags.isEmpty {
              ForEach(Array(sampleObj.tags), id: \.self) { tagName in
                TagComponent(string: tagName)
              }
            }
          }
        }
      }
      
      Spacer()
      
      if #unavailable(macOS 26.0) {
        StaticWaveformView(fileURL: sample.file.fileURL)
          .frame(maxWidth: 200, maxHeight: 20)
      }
      
      Spacer()
      HStack {
        // show extension of the sample
        Text(sample.file.fileURL.pathExtension.uppercased())
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        
        Button {
//          viewModel.predicateSelection = sample.id
          viewModel.showInspector = true
        } label: {
          Image(systemName: "info.circle")
        }
        .buttonStyle(.borderless)
      }
    }
    .frame(minHeight: 40, maxHeight: 40)
    .draggable(sample) {
      // example view for now
      Label(sample.file.fileURL.lastPathComponent, systemImage: "waveform")
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
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

#Preview {
  RecordingsListView(viewModel: SampleLibraryViewModel(), predicate: .all)
    .frame(width:600, height: 700)
}
