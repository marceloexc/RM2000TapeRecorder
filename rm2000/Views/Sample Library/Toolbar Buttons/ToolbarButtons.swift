import SwiftUI

struct SidebarButton: View {
	var body: some View {
		Button(action: toggleSidebar) {
			Label("Reveal Sidebar", systemImage: "sidebar.leading")
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
				Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"))
					.resizable()
					.scaledToFit()
					.frame(width: 25, height: 25)
			}
		}
		.buttonStyle(.plain)
		.help("Open in Finder")
	}
}

struct ShareSampleButton: View {
	var body: some View {
		Button(action: {
			print("Shared button pressed")
		}) {
			Label("Share Sample", systemImage: "square.and.arrow.up")
				.fontWeight(.black)
				.foregroundStyle(.orange)
		}
		.buttonStyle(.borderless)
		.padding(.bottom, 3) // or else it looks weirdly positioned!
	}
}

struct ImportSampleButton: View {
	var body: some View {
		Button(action: {
			NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
		}) {
			Label("Import Sample", systemImage: "plus")
				.fontWeight(.black)
				.foregroundStyle(.green)
		}
		.buttonStyle(.borderless)
		.help("Import a Sample")
	}
}

func toggleSidebar() {
#if os(macOS)
	NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
#endif
}


func setToolbarStyle() {
#if os(macOS)
	if let window = NSApp.windows.first(where: { $0.isKeyWindow }),
		 let toolbar = window.toolbar {
		toolbar.displayMode = .iconAndLabel
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
	}
#endif
}
