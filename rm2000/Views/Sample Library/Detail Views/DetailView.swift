import SwiftUI

enum DetailViewType: String {
  case list
  case table
}

struct DetailView: View {
  @StateObject var viewModel: SampleLibraryViewModel
  
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
        RecordingsTableView(viewModel: viewModel, predicate: currentFilter)
      }
    }
    .onChange(of: viewModel.sidebarSelection) { oldValue, newValue in
      viewModel.predicateSelection = []
    }
  }
}

struct ContextMenu {
  static func openInDefaultApp(urls: [URL]) {
    for url in urls {
      NSWorkspace.shared.open(url)
    }
  }
  
  static func copyToClipboard(urls: [URL]) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.declareTypes([.fileURL], owner: nil)
    pasteboard.writeObjects(urls as [NSPasteboardWriting])
  }
  
  static func revealFinder(urls: [URL]) {
    NSWorkspace.shared.activateFileViewerSelecting(urls)
  }
  
  static func moveToTrash(urls: [URL]) {
    for url in urls {
      try! FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
  }
  
  static func editSample(sample: Sample, appDelegate: AppDelegate) {
    appDelegate.showEditingWindow(sample: sample)
  }
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
}
