import SwiftUI

struct DetailView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		Group {
			if let selectedTag = viewModel.sidebarSelection {
				TaggedRecordingsView(viewModel: viewModel, selectedTag: selectedTag)
			} else {
				AllRecordingsView(viewModel: viewModel)
			}
		}
	}
}

private struct TaggedRecordingsView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	let selectedTag: String
	
	var body: some View {
		
		if viewModel.finishedProcessing {
			List(viewModel.listOfAllSamples, selection: $viewModel.detailSelection) { sample in
				if sample.tags.contains(selectedTag) {
					let itemModel = SampleListItemModel(file: sample)
					SampleIndividualListItem(sample: itemModel)
				}
			}
		}
		

	}
}

struct AllRecordingsView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		Group {
			if viewModel.finishedProcessing {
				List(viewModel.listOfAllSamples, selection: $viewModel.detailSelection) { sample in
					
					let itemModel = SampleListItemModel(file: sample)
					SampleIndividualListItem(sample: itemModel)
				}
				.listStyle(.plain)
			} else {
				ProgressView("Loading recordings...")
			}
		}
	}
}

struct SampleIndividualListItem: View {
	@Environment(\.openWindow) var openWindow
	var sample: SampleListItemModel
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 4) {
				Text(sample.text)
					.font(.title3)
				HStack(spacing: 8) {
					
					// todo - make tag its each view component
					// so that we can check if we need it by seeing if SampleListModel is Sample or not
//					ForEach(Array(sample.tags), id:\.self) { tagName in
//						Text(tagName)
//							.font(.caption)
//							.padding(2)
//							.background(Color.gray.opacity(0.2))
//							.cornerRadius(3)
//					}
				}
			}
			
			Spacer()
			
			HStack {
				Button {
					openWindow(id: "inspector")
				} label: {
					Image(systemName: "info.circle.fill")
				}
				.buttonStyle(.automatic)
				.controlSize(.small)
			}
		}
		.contentShape(Rectangle())
		.onTapGesture(count: 2) {
			NSWorkspace.shared.open(sample.file.fileURL)
		}
		.contextMenu {
			Button("Open File") {
				NSWorkspace.shared.open(sample.file.fileURL)
			}
		}
	}
}

#Preview {
	SampleLibraryView()
		.environmentObject(SampleStorage.shared)
}
