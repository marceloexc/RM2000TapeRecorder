import SwiftUI

enum DetailViewType: Hashable {
  case all
  case tagged(String)
  case untagged
}

enum DetailViewMode: String {
  case list
  case table
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
    ZStack {
      switch currentViewType {
      case .all:
        RecordingsTableView(viewModel: viewModel, viewType: .all)
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
