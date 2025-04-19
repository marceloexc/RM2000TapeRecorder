import Foundation
import Combine
import SwiftUI

extension ToolbarItemPlacement {
	static let favoritesBar = accessoryBar(id: "com.example.favorites")
}

struct SampleLibraryView: View {
	@StateObject private var viewModel: SampleLibraryViewModel
	@Environment(\.openURL) private var openURL
	
	@State private var currentSamplesInView: Int = 0
	@State private var selection = "Apple"
	
	let options = ["Apple", "Banana"]
	
	
	init() {
			_viewModel = StateObject(wrappedValue: SampleLibraryViewModel())
	}
	
	var body: some View {
		NavigationSplitView {
			SidebarView(viewModel: viewModel)
		} content: {
			DetailView(viewModel: viewModel)
				.toolbar(id: "content-toolbar"){
					
					/*
					 theres this gnarly bug where if i select "Icon and Text" in the
					 context menu of the toolbar, the sidebar button (now with the
					 text) will cause the app to freeze. I dont know what causes this.
					 Even apples official tutorial apps, downloaded from their dev site
					 and built with xcode, which are meant to show the engineering
					 prowess of swifui, have this same bug. So i guess no customiziable
					 toolbars!
					 
					 This is why all of the buttons have a hacky workaround where I just
					 put a Text with a caption font for it to act like "Icon and Text" is
					 on. Which is the correct way all toolbars should be...
					 
					 */
					
					// UUID() as the id's to workaround a nasty swiftui bug
					
					// or else they just wont show up...stupid...
					ToolbarItem(id: UUID().uuidString) {
						Picker("View settings", selection: $selection) {
							Label("Grid", systemImage: "square.grid.2x2")
							Label("List", systemImage: "list.bullet")
						}.pickerStyle(.inline)
					}
					ToolbarItem(id:UUID().uuidString){
						ImportSampleButton()
					}
					ToolbarItem(id: UUID().uuidString, placement: .favoritesBar) {
						Text("Player")
					}
				}
		} detail: {
			let testFile = URL(fileURLWithPath: "/Users/marceloexc/Developer/replica/rm2000Tests/Example--sample.aac")
			let recording = TemporaryActiveRecording(fileURL: testFile)
			EditSampleView(recording: recording) { _, _, _ in
				// Empty completion handler
				
			}
			.toolbar(id: "detail-toolbar") {
				ToolbarItem(id: "spacer") {
					Spacer()
				}
				ToolbarItem(id: "finder-button") {
					OpenInFinderButton()
				}
			}
		}
		.toolbarRole(.automatic)
		.navigationTitle("Sample Library")
		.navigationSubtitle("\(currentSamplesInView) Samples")

		.task {
			currentSamplesInView = viewModel.listOfAllSamples.count
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
					.frame(width: 20, height: 20)
				Text("Show in Finder")
					.font(.caption)
			}
		}
		.buttonStyle(PlainButtonStyle())
		.help("Open in Finder")
	}
}

struct ImportSampleButton: View {
	var body: some View {
		Button(action: {
			NSWorkspace.shared.open(SampleStorage.shared.UserDirectory.directory)
		}) {
			Label("Import Sample", systemImage: "plus.circle.fill")
					.fontWeight(.black)
					.foregroundStyle(.green)
		}
		.buttonStyle(.borderless)
		.help("Import a Sample")
	}
}

@MainActor
class SampleLibraryViewModel: ObservableObject {
	@Published var listOfAllSamples: [Sample] = []
	@Published var indexedTags: [String] = []
	@Published var finishedProcessing: Bool = false
	@Published var currentSelection: String?
	
	private var sampleStorage: SampleStorage
	private var cancellables = Set<AnyCancellable>()
	
	@MainActor
	init(sampleStorage: SampleStorage = SampleStorage.shared) {
		self.sampleStorage = sampleStorage
		
		sampleStorage.UserDirectory.$files
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newFiles in
				self?.listOfAllSamples = newFiles
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
}

#Preview {
	SampleLibraryView()
		.environmentObject(SampleStorage.shared)
}
