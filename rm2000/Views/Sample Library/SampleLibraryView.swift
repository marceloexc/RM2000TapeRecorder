import Foundation
import Combine
import SwiftUI

@MainActor
struct SampleLibraryView: View {
	@StateObject private var viewModel: SampleLibraryViewModel
	@Environment(\.openURL) private var openURL
	
	@State private var totalSamples: Int = 0
	
	init() {
			_viewModel = StateObject(wrappedValue: SampleLibraryViewModel())
	}
	
	var body: some View {
		NavigationSplitView {
			SidebarView(viewModel: viewModel)
				.listStyle(SidebarListStyle())
		} detail: {
			DetailView(viewModel: viewModel)
		}
		.navigationTitle("Sample Library")
		.navigationSubtitle(String(totalSamples))
		.toolbar {
			ToolbarItem {
				OpenInFinderButton()
			}
		}
		.task {
			totalSamples = viewModel.sampleArray.count
		}
		.searchable(text: .constant(""), placement: .sidebar)
	}
}

struct OpenInFinderButton: View {
	var body: some View {
		Button(action: {
			NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
		}) {
			VStack {
				Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"))
					.resizable()
					.scaledToFit()
					.frame(width: 20, height: 20) // Adjust size as needed
				Text("Show in Finder")
					.font(.caption)
			}
		}
		.buttonStyle(PlainButtonStyle())
		.help("Open in Finder")
	}
}


@MainActor
class SampleLibraryViewModel: ObservableObject {
	@Published var sampleArray: [Sample] = []
	@Published var indexedTags: [String] = []
	@Published var finishedProcessing: Bool = false
	@Published var selectedTag: String?
	
	private var sampleStorage: SampleStorage
	private var cancellables = Set<AnyCancellable>()
	
	@MainActor
	init(sampleStorage: SampleStorage = SampleStorage.shared) {
		self.sampleStorage = sampleStorage
		
		sampleStorage.UserDirectory.$files
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newFiles in
				self?.sampleArray = newFiles
				self?.finishedProcessing = true
			}
			.store(in: &cancellables)
		
		sampleStorage.UserDirectory.$indexedTags
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newTags in
				self?.indexedTags = Array(newTags).sorted()
			}
			.store(in: &cancellables)
	}
	
	func refresh() {
		// Force refresh logic
	}
}
