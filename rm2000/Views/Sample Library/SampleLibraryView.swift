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
		
	init() {
			_viewModel = StateObject(wrappedValue: SampleLibraryViewModel())
	}
	
	var body: some View {
		NavigationSplitView {
			SidebarView(viewModel: viewModel)
				.toolbar(removing: .sidebarToggle)
		} detail: {
			DetailView(viewModel: viewModel)
		}
		.toolbar(id: "rm2000.main-toolbar"){
			ToolbarItem(id: "rm2000.share.button") {
				ShareSampleButton()
			}
			ToolbarItem(id: "rm2000.spacer") {
				Spacer()
			}
			ToolbarItem(id: "rm2000.import-sample-button", placement: .primaryAction) {
				ImportSampleButton()
			}
			ToolbarItem(id: "rm2000.spacer") {
				Spacer()
			}
			ToolbarItem(id: "rm2000.open-in-finder-button", placement: .primaryAction) {
				OpenInFinderButton()
			}
			
			ToolbarItem(id: "rm2000.divider", placement: .primaryAction) {
				HStack {
					Divider()
				}
			}
			ToolbarItem(id: "rm2000.picker", placement: .primaryAction) {
				Picker("View settings", selection: $selection) {
					Label("Grid", systemImage: "square.grid.2x2")
					Label("List", systemImage: "list.bullet")
				}.pickerStyle(.inline)
			}
			ToolbarItem(id: UUID().uuidString, placement: .favoritesBar) {
				Button {
					viewModel.slAudioPlayer.playPause()
				} label: {
					Image(systemName: viewModel.slAudioPlayer.isPlaying ? "pause.fill" : "play.fill")
				}
				.disabled(viewModel.selectedSample == nil)

			}
			ToolbarItem(id: "rm2000.sidebar", placement: .navigation) {
				SidebarButton()
			}
			ToolbarItem(id: UUID().uuidString, placement: .favoritesBar) {
				Slider(
					value: Binding(
						get: { viewModel.slAudioPlayer.currentTime },
						set: { viewModel.slAudioPlayer.seekTo(time: $0) }
					),
					in: 0...viewModel.slAudioPlayer.duration
				)
				.disabled(viewModel.selectedSample == nil)
			}
			
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
			
		}
		.inspector(isPresented: $viewModel.showInspector) {

				InspectorView(viewModel: viewModel)
			
			.toolbar(id: "rm2000.inspector.toolbar") {
				ToolbarItem(id: "rm2000.spacer") {
					Spacer()
				}
				ToolbarItem(id: "rm2000.inspector.button") {
					Button {
						viewModel.showInspector.toggle()
					} label: {
						Label("Toggle Inspector", systemImage: "sidebar.right")
					}
				}
			}
			.inspectorColumnWidth(min: 300, ideal: 400, max: 500)
		}
		.toolbarRole(.editor)
		.navigationTitle("Sample Library")
		.navigationSubtitle("\(currentSamplesInView) Samples")
		.onAppear {
			// automatically set toolbar to "Icon and Label"
			setToolbarStyle()
		}
		.task {
			currentSamplesInView = viewModel.listOfAllSamples.count
		}
		.searchable(text: .constant(""), placement: .sidebar)
	}
}

@MainActor
class SampleLibraryViewModel: ObservableObject {
	@Published var listOfAllSamples: [Sample] = []
	@Published var indexedTags: [String] = []
	@Published var finishedProcessing: Bool = false
	@Published var sidebarSelection: String?
	@Published var detailSelection: SampleListItemModel.ID?
	@Published var showInspector: Bool = true
	@Published var slAudioPlayer = SLAudioPlayer()
	
	private var sampleStorage: SampleStorage
	private var cancellables = Set<AnyCancellable>()
	
	var selectedSample: Sample? {
		return matchToSample(id: detailSelection)
	}
	
	init(sampleStorage: SampleStorage = SampleStorage.shared) {
		self.sampleStorage = sampleStorage
		
		sampleStorage.UserDirectory.$files
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newFiles in
				print("NEW FILES RECIEVED \(newFiles)")
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
		
		// Watch for changes in selection and update audio player
		$detailSelection
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newSelection in
				guard let self = self else { return }
				if let sample = self.matchToSample(id: newSelection) {
					self.slAudioPlayer.loadAudio(from: sample.fileURL)
				}
			}
			.store(in: &cancellables)
	}

	private func matchToSample(id: UUID?) -> Sample? {
		// match uuid from detailSelection to its according sample object
		guard let id = id else { return nil }
		return listOfAllSamples.first { $0.id == id }
	}
}

struct SampleListItemModel: Identifiable, Hashable {
	var id: UUID
	var text: String
	var file: FileRepresentable
	
	init(file: FileRepresentable) {
		if let sample = file as? Sample {
			self.id = sample.id 
			self.text = sample.title
		} else {
			self.id = UUID()
			self.text = file.fileURL.lastPathComponent
		}
		self.file = file
	}
	
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: SampleListItemModel, rhs: SampleListItemModel) -> Bool {
		return lhs.id == rhs.id
	}
}

#Preview {
	SampleLibraryView()
		.environmentObject(SampleStorage.shared)
		.frame(width: 900)
}
