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

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
}
