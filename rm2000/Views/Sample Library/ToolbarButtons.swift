import SwiftUI

struct SidebarButton: View {
  var body: some View {
    Button(action: toggleSidebar) {
      Label("Sidebar", systemImage: "sidebar.leading")
        .foregroundStyle(.teal)
    }
  }
}

struct OpenInFinderButton: View {
  var body: some View {
    Button(action: {
      NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
    }) {
      Label {
        Text("Open in Finder")
      } icon: {
        Image("SmallHappyFolder")
        .resizable()
        .scaledToFit()
        //					.frame(width: 20, height: 20)
      }
    }
    .help("Open in Finder")
  }
}

struct ShareSampleButton: View {
  var selectedItems: [FileRepresentable]?

  private var shareURL: [URL] {
    if selectedItems?.count == 1 {
      return [selectedItems?.first!.fileURL ?? Bundle.main.bundleURL]
    } else if let selectedItems = selectedItems {
      return selectedItems.compactMap(\.fileURL)
    }
    return []
  }

  private var shareTitle: String {
    return "Sample"
  }

  var body: some View {
    ShareLink(items: shareURL)
//    ShareLink(
//      item: shareURL,
//      preview: SharePreview(
//        shareTitle,
//        icon: Image(
//          nsImage: NSWorkspace.shared.icon(forFile: shareURL.description))
//      )
//    ) {
//      Label("Share", systemImage: "square.and.arrow.up")
//    }
//    .disabled(selectedItems == nil)
//    .help(
//      selectedItems != nil ? "Share \(selectedItems!.count) files" : "No sample selected")
  }
}

struct ImportSampleButton: View {
  var body: some View {
    Button(action: {
      NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
    }) {
      Label("Import", systemImage: "plus")
        //				.fontWeight(.black)
        .foregroundStyle(.green)
    }
    .help("Import a Sample")
  }
}

struct ViewModeButton: View {
  
  @Binding var selection: DetailViewType
  var body: some View {
    Picker("View", selection: $selection) {
      Label("Table", systemImage: "table").tag(DetailViewType.table)
      Label("List", systemImage: "list.bullet").tag(DetailViewType.list)
    }.pickerStyle(.segmented)
  }
}

func toggleSidebar() {
  #if os(macOS)
    NSApp.keyWindow?.firstResponder?.tryToPerform(
      #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  #endif
}

func setToolbarStyle() {
  #if os(macOS)
    if let window = NSApp.windows.first(where: { $0.isKeyWindow }),
      let toolbar = window.toolbar
    {
      toolbar.displayMode = .iconAndLabel
      toolbar.allowsUserCustomization = true
      toolbar.autosavesConfiguration = true
    }
  #endif
}
