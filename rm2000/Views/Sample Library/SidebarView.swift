import SwiftUI

enum SidebarSelection: Hashable {
	case allRecordings
	case untaggedRecordings
	case tag(String)
}

struct SidebarView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		List(selection: $viewModel.sidebarSelection) {
			Section(header: Text("Collections")) {
				NavigationLink(value: SidebarSelection.allRecordings) {
					Label("All Recordings", systemImage: "folder")
				}
				NavigationLink(value: SidebarSelection.untaggedRecordings) {
					HStack {
						Image("untagged")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.red, Color.accentColor)
						
						Text("Untagged")
					}
				}
			}
			Section(header: Text("Available tags")) {
				ForEach(viewModel.indexedTags, id: \.self) { tagName in
					NavigationLink(value: SidebarSelection.tag(tagName)) {
						Label("\(tagName)", systemImage: "number")
					}
				}
			}
		}
	}
}

#Preview("Sidebar View") {
	let vm = SampleLibraryViewModel()
	return SidebarView(viewModel: vm)
}
