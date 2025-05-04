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
			List(viewModel.listOfAllSamples, id: \.id, selection: $viewModel.detailSelection) { sample in
				if sample.tags.contains(selectedTag) {
					let itemModel = SampleListItemModel(file: sample)
					SampleIndividualListItem(sample: itemModel)
						.tag(sample.id)
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
				List(viewModel.listOfAllSamples, id: \.id, selection: $viewModel.detailSelection) { sample in
					
					let itemModel = SampleListItemModel(file: sample)
					let _ = print("Now selected from all recordings: :\(viewModel.detailSelection)")

					SampleIndividualListItem(sample: itemModel)
						.tag(sample)
					/*
					 todo - fix this bug where, when uncommented below,
					 selecting the list item will only work when selecting
					 the background, not the text
					 
					 
					 .onTapGesture(count: 2) {
					 NSWorkspace.shared.open(sample.fileURL)
					 }
					 */
				}
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
				Text("\(sample.text) - \(sample.id)")
					.font(.title3)
				if let sampleObj = sample.file as? Sample, !sampleObj.tags.isEmpty {
					HStack(spacing: 8) {
						ForEach(Array(sampleObj.tags), id: \.self) { tagName in
							Text(tagName)
								.font(.caption)
								.padding(2)
								.background(Color.gray.opacity(0.2))
								.cornerRadius(3)
						}
					}
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
