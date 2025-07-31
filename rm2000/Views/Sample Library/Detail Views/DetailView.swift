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
        RecordingsTableView(viewModel: viewModel, predicate: currentFilter)
      }
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
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
}
