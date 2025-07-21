import SwiftUI


enum DetailViewType: String {
  case list
  case table
}

struct DetailView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel
  
  var currentFilter: SampleFilterPredicate {
    viewModel.sidebarSelection
  }

  
  @Binding var currentView: DetailViewType

  var body: some View {
    ZStack {
      switch currentView {
      case .list:
        RecordingsListView(viewModel: viewModel, predicate: currentFilter)
      case .table:
        RecordingsTableView(viewModel: viewModel, viewType: currentFilter)
      }
    }
  }
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
}
