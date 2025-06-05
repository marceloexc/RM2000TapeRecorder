import SwiftUI

enum DetailViewType: Hashable {
  case all
  case tagged(String)
  case untagged
}

struct DetailView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel

  private var currentViewType: DetailViewType {
    guard let selection = viewModel.sidebarSelection else {
      return .all
    }

    switch selection {
    case .allRecordings:
      return .all
    case .untaggedRecordings:
      return .untagged
    case .tag(let tagName):
      return .tagged(tagName)
    }
  }

  var body: some View {
    Group {
      switch currentViewType {
      case .all:
        RecordingsListView(viewModel: viewModel, viewType: .all)
      case .tagged(let tagName):
        RecordingsListView(viewModel: viewModel, viewType: .tagged(tagName))
      case .untagged:
        RecordingsListView(viewModel: viewModel, viewType: .untagged)
      }
    }
  }
}

private struct RecordingsListView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel
  let viewType: DetailViewType

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
    Group {
      if viewModel.finishedProcessing {
        List(filteredSamples, id: \.id, selection: $viewModel.detailSelection) {
          sample in
          let itemModel = SampleListItemModel(file: sample)
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
  @ObservedObject var viewModel: SampleLibraryViewModel
  @Environment(\.openWindow) var openWindow
  var sample: SampleListItemModel

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

      StaticWaveformView(fileURL: sample.file.fileURL)
        .frame(maxWidth: 200, maxHeight: 20)

      Spacer()
      HStack {
        // show extension of the sample
        Text(sample.file.fileURL.pathExtension.uppercased())
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.semibold)
          .foregroundColor(.secondary)

        Button {
          viewModel.detailSelection = sample.id
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
      Button("Open File") {
        NSWorkspace.shared.open(sample.file.fileURL)
      }
    }
  }
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
}
