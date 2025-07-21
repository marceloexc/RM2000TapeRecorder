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
  var sampleItem: Sample?

  private var shareURL: URL {
    sampleItem?.fileURL ?? Bundle.main.bundleURL
  }

  private var shareTitle: String {
    sampleItem?.filename ?? "No Sample Selected"
  }

  var body: some View {
    ShareLink(
      item: shareURL,
      preview: SharePreview(
        shareTitle,
        icon: Image(
          nsImage: NSWorkspace.shared.icon(forFile: shareURL.description))
      )
    ) {
      Label("Share", systemImage: "square.and.arrow.up")
    }
    .disabled(sampleItem == nil)
    .help(
      sampleItem != nil ? "Share \(sampleItem!.title)" : "No sample selected")
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
