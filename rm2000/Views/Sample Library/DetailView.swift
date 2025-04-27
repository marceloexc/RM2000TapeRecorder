import SwiftUI

struct DetailView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		Group {
			if let selectedTag = viewModel.currentSelection {
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
			List(viewModel.listOfAllSamples) { sample in
				if sample.tags.contains(selectedTag) {
					SampleIndividualListItem(sampleItem: sample)
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
				List(viewModel.listOfAllSamples) { sample in
					SampleIndividualListItem(sampleItem: sample)
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
	var sampleItem: Sample
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 4) {
				Text(sampleItem.title)
					.font(.title3)
				HStack(spacing: 8) {
					ForEach(Array(sampleItem.tags), id:\.self) { tagName in
						Text(tagName)
							.font(.caption)
							.padding(2)
							.background(Color.gray.opacity(0.2))
							.cornerRadius(3)
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
		.contentShape(Rectangle())
		.onTapGesture(count: 2) {
			NSWorkspace.shared.open(sampleItem.fileURL)
		}
		.contextMenu {
			Button("Open File") {
				NSWorkspace.shared.open(sampleItem.fileURL)
			}
		}
	}
}

#Preview {
	SampleLibraryView()
		.environmentObject(SampleStorage.shared)
}
