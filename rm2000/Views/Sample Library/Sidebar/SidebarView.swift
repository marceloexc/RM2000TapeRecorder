import SwiftUI

struct SidebarView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		List(selection: $viewModel.selectedTag) {
			NavigationLink {
				AllRecordingsView(viewModel: viewModel)
			} label: {
				Label("All Recordings", systemImage: "waveform.path")
			}
			Section(header: Text("Available tags")) {
				ForEach(viewModel.indexedTags, id: \.self) { tagName in
					NavigationLink(value: tagName) {
						Label("#\(tagName)", systemImage: "waveform.path")
					}
				}
			}
		}
	}
}

#Preview("Sidebar View") {
	let vm = SampleLibraryViewModel()
	vm.indexedTags = ["drums", "bass", "vocals"]
	vm.finishedProcessing = true
	return SidebarView(viewModel: vm)
}
