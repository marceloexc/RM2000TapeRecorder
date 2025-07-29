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
  var selectedItems: [FileRepresentableItemModel]?
  
  private var validURLs: [URL] {
    selectedItems?.compactMap { $0.file.fileURL } ?? []
  }
  
  var body: some View {
    ShareLink(
      items: validURLs,
      subject: Text("Samples"),
      message: Text("Sharing \(validURLs.count) samples")) { item in
      SharePreview(item.lastPathComponent, icon: Image(nsImage: NSWorkspace.shared.icon(forFile: item.path)))
    } label: {
      Label("Share", systemImage: "square.and.arrow.up")
    }
    .disabled(validURLs.isEmpty)
    .help(validURLs.isEmpty ? "No sample selected" : "Share \(validURLs.count) file(s)")
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
