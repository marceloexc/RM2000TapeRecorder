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

  
  var currentView: DetailViewType = .list

  var body: some View {
    ZStack {
      RecordingsListView(viewModel: viewModel, predicate: currentFilter)
    }
  }
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
}
