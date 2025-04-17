import SwiftUI

struct SidebarView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		List(selection: $viewModel.currentSelection) {
			Section(header: Text("Collections")) {
				NavigationLink {
					AllRecordingsView(viewModel: viewModel)
				} label: {
					Label("All Recordings", systemImage: "folder")
				}
			}
			Section(header: Text("Available tags")) {
				ForEach(viewModel.indexedTags, id: \.self) { tagName in
					NavigationLink(value: tagName) {
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
