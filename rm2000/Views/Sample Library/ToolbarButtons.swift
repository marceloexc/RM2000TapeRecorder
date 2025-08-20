import SwiftUI

struct SidebarButton: View {
  var body: some View {
    Button(action: toggleSidebar) {
      Label("Sidebar", systemImage: "sidebar.squares.left")
        .foregroundStyle(Color.accentColor)
    }
  }
}

struct OpenInFinderButton: View {
  var body: some View {
    Button(action: {
      NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
    }) {
      Label("Reveal Folder", systemImage: "folder.fill")
        .foregroundStyle(Color.init(hex: 0x7177d5))
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
        Label("Share", systemImage: "arrowshape.turn.up.left.fill")
          .foregroundStyle(.secondary)
          .fontWeight(.semibold)
          .scaleEffect(x: -1, y: 1) //flip
      }
      else {
        Label("Share", systemImage:"arrowshape.turn.up.left.fill")
          .foregroundStyle(.orange)
          .fontWeight(.semibold)
          .scaleEffect(x: -1, y: 1) //flip
      }
    }
    .disabled(validURLs.isEmpty)
    .help(validURLs.isEmpty ? "No sample selected" : "Share \(validURLs.count) file(s)")
  }
}

struct EditSampleButton: View {
  var selectedItems: [FileRepresentableItemModel]?
  
  private var validURLs: [URL] {
    selectedItems?.compactMap { $0.file.fileURL } ?? []
  }
  
  var body: some View {
    Button {
      print("hello world")
    } label: {
      if validURLs.isEmpty {
        Label("Edit", systemImage: "slider.horizontal.3")
          .foregroundStyle(.secondary)
          .fontWeight(.bold)
      }
      else {
        Label("Edit", systemImage: "slider.horizontal.3")
          .foregroundStyle(Color.init(hex: 0xec5962))
          .fontWeight(.bold)
      }
    }
    .disabled(validURLs.isEmpty)
  }
}

struct ImportSampleButton: View {
  @Binding var isShowingSheet: Bool

  var body: some View {
    Button(action: {
      isShowingSheet = true
    }) {
      Label("Import", systemImage: "plus")
        				.fontWeight(.black)
        .foregroundStyle(.green)
    }
    .help("Import a Sample")
  }
}

struct ViewModeButton: View {
  
  @Binding var selection: DetailViewType
  var body: some View {
    Picker("View", selection: $selection) {
      Label("Table", systemImage: "rectangle.split.3x1.fill")
        .tag(DetailViewType.table)
      Label("List", systemImage: "list.bullet.rectangle.fill")
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
//      toolbar.displayMode = .iconAndLabel
      toolbar.allowsUserCustomization = true
      toolbar.autosavesConfiguration = true
    }
  #endif
}
