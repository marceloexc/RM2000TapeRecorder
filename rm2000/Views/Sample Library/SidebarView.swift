import SwiftUI

enum SampleFilterPredicate: Hashable {
	case all
	case untagged
	case tagged(String)
}

struct SidebarView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	init(viewModel: SampleLibraryViewModel) {
		self.viewModel = viewModel
	}
	
	var body: some View {
		List(selection: $viewModel.sidebarSelection) {
			Section(header: Text("Collections")) {
				NavigationLink(value: SampleFilterPredicate.all) {
					Label("All Recordings", systemImage: "folder")
				}
				NavigationLink(value: SampleFilterPredicate.untagged) {
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
					NavigationLink(value: SampleFilterPredicate.tagged(tagName)) {
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
