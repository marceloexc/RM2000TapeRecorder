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
					SampleIndividualListItem(viewModel: viewModel, sample: itemModel)
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

					SampleIndividualListItem(viewModel: viewModel, sample: itemModel)
						.tag(sample.id)
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
	@ObservedObject var viewModel: SampleLibraryViewModel
	@Environment(\.openWindow) var openWindow
	var sample: SampleListItemModel
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 4) {
				Text("\(sample.text)")
					.font(.title3)
				if let sampleObj = sample.file as? Sample, !sampleObj.tags.isEmpty {
					HStack(spacing: 8) {
						ForEach(Array(sampleObj.tags), id: \.self) { tagName in
							TagComponent(tagName: tagName)
						}
					}
				}
			}
			
			Spacer()
			
			StaticWaveformView(fileURL: sample.file.fileURL)
				.frame(maxWidth: 200, maxHeight: 20)
			
			Spacer()
			HStack {
				// show extension of the sample
				Text(sample.file.fileURL.pathExtension.uppercased())
					.font(.system(.caption, design: .monospaced))
					.fontWeight(.semibold)
					.foregroundColor(.secondary)
				
				Button {
					viewModel.detailSelection = sample.id
					viewModel.showInspector = true
				} label: {
					Image(systemName: "info.circle")
				}
				.buttonStyle(.borderless)
			}
		}
		.draggable(sample) {
			// example view for now
			Label(sample.file.fileURL.lastPathComponent, systemImage: "waveform")
				.padding()
				.background(Color(NSColor.windowBackgroundColor))
				.cornerRadius(8)
				.shadow(radius: 2)
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
