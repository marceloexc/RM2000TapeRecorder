import SwiftUI

struct SidebarButton: View {
  var body: some View {
    Button(action: toggleSidebar) {
      Label("Sidebar", systemImage: "rectangle.leftthird.inset.filled")
        .foregroundStyle(Color.accentColor)
    }
  }
}

struct OpenInFinderButton: View {
  var body: some View {
    Button(action: {
      NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
    }) {
      Label("Reveal Folder", systemImage: "folder.badge.person.crop")
        .foregroundStyle(.teal)
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
      if validURLs.isEmpty {
        Label("Share", systemImage: "square.and.arrow.up")
//          .fontWeight(.semibold)
      }
      else {
        Label("Share", image: "share_file")
          .foregroundStyle(.orange)
          .fontWeight(.semibold)
      }
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
      Label("Table", systemImage: "rectangle.split.3x1")
        .tag(DetailViewType.table)
      Label("List", systemImage: "list.bullet")
        .tag(DetailViewType.list)
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
