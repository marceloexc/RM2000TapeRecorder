import Foundation
import Combine
import SwiftUI
import OSLog

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
				.navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
		} detail: {
			DetailView(viewModel: viewModel)
				.navigationSplitViewColumnWidth(min: 500, ideal: 500)
		}
		.toolbar(id: "rm2000.main-toolbar"){
			
			ToolbarItem(id: "rm2000.sidebar", placement: .navigation) {
				SidebarButton()
			}
			ToolbarItem(id: "rm2000.share.button", placement: .primaryAction) {
				ShareSampleButton()
			}
			ToolbarItem(id: "rm2000.import-sample-button", placement: .primaryAction) {
				ImportSampleButton()
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
				Picker("View", selection: $selection) {
					Label("Grid", systemImage: "square.grid.2x2")
					Label("List", systemImage: "list.bullet")
				}.pickerStyle(.menu)
			}

		}
		.toolbar(id: "rm2000.favorites-toolbar") {
			ToolbarItem(id: "rm2000.playpause", placement: .favoritesBar) {
				Button {
					viewModel.slAudioPlayer.playPause()
				} label: {
					Image(systemName: viewModel.slAudioPlayer.isPlaying ? "pause.fill" : "play.fill")
				}
				.disabled(viewModel.selectedSample == nil)
			}
			
			ToolbarItem(id: "rm2000.duration", placement: .favoritesBar) {
				if (viewModel.slAudioPlayer.isPlaying) {
					// https://stackoverflow.com/questions/33401388/get-minutes-and-seconds-from-double-in-swift
					let mins: Int = Int(viewModel.slAudioPlayer.currentTime) / 60
					let secs: Int = Int(viewModel.slAudioPlayer.currentTime - Double(mins * 60))
					Text(String(format: "%d:%02d", mins, secs))
				}
				else {
					Text("0:00")
						.disabled(viewModel.selectedSample == nil)
				}
			}
			
			ToolbarItem(id: "rm2000.slider", placement: .favoritesBar) {
				Slider(
					value: Binding(
						get: { viewModel.slAudioPlayer.currentTime },
						set: { viewModel.slAudioPlayer.seekTo(time: $0) }
					),
					in: 0...viewModel.slAudioPlayer.duration
				)
				.disabled(viewModel.selectedSample == nil)
			}
			
			ToolbarItem(id: "rm2000.autoplay-toggle", placement: .favoritesBar) {
				Toggle( "Autoplay",
								isOn: $viewModel.slAudioPlayer.isAutoplay
				).toggleStyle(.checkbox)
			}
			
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
						Label("Inspector", systemImage: "info.circle")
							.foregroundStyle(.cyan)

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


#Preview {
	SampleLibraryView()
		.environmentObject(SampleStorage.shared)
		.frame(width: 900)
}
