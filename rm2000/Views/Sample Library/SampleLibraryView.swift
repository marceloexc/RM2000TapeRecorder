import Combine
import Foundation
import OSLog
import SwiftUI

extension ToolbarItemPlacement {
  static let favoritesBar = accessoryBar(id: "com.example.favorites")
}

struct SampleLibraryView: View {
  @StateObject private var viewModel: SampleLibraryViewModel
  @Environment(\.openURL) private var openURL
  @Environment(\.controlActiveState) private var controlActiveState
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
    .toolbar(id: "rm2000.main-toolbar") {

      ToolbarItem(id: "rm2000.sidebar", placement: .navigation) {
        SidebarButton()
      }.customizationBehavior(.disabled)
      ToolbarItem(id: "rm2000.share.button", placement: .primaryAction) {
        ShareSampleButton(sampleItem: viewModel.selectedSample)
      }
      //      ToolbarItem(id: "rm2000.import-sample-button", placement: .primaryAction)
      //      {
      //        ImportSampleButton()
      //      }
      ToolbarItem(id: "rm2000.open-in-finder-button", placement: .primaryAction)
      {
        OpenInFinderButton()
      }

      ToolbarItem(id: "rm2000.divider", placement: .primaryAction) {
        HStack {
          Divider()
        }
      }
      //      ToolbarItem(id: "rm2000.picker", placement: .primaryAction) {
      //        Picker("View", selection: $selection) {
      //          Label("Grid", systemImage: "square.grid.2x2")
      //          Label("List", systemImage: "list.bullet")
      //        }.pickerStyle(.menu)
      //      }
    }
    .toolbar(id: "rm2000.favorites-toolbar") {
      ToolbarItem(id: "rm2000.playpause", placement: .favoritesBar) {
        Button {
          viewModel.slAudioPlayer.playPause()
        } label: {
          Image(
            systemName: viewModel.slAudioPlayer.isPlaying
              ? "pause.fill" : "play.fill")
        }
        .disabled(viewModel.selectedSample == nil)
      }
      ToolbarItem(id: "rm2000.duration", placement: .favoritesBar) {
        if viewModel.slAudioPlayer.isPlaying {
          let mins: Int = Int(viewModel.slAudioPlayer.currentTime) / 60
          let secs: Int = Int(
            viewModel.slAudioPlayer.currentTime - Double(mins * 60))
          Text(String(format: "%d:%02d", mins, secs))
        } else {
          Text("0:00")
            .disabled(viewModel.selectedSample == nil)
        }
      }
      ToolbarItem(id: "rm2000.slider", placement: .favoritesBar) {
        Slider(
          value: Binding(
            get: { viewModel.currentTime },
            set: { viewModel.slAudioPlayer.seekTo(time: $0) }
          ),
          in: 0...viewModel.slAudioPlayer.duration
        )
        .disabled(viewModel.selectedSample == nil)
      }

      ToolbarItem(id: "rm2000.autoplay-toggle", placement: .favoritesBar) {
        Toggle(
          "Autoplay",
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
    .navigationSubtitle("\(viewModel.filteredSamples.count) Samples")
    .onAppear {
      setToolbarStyle()
    }
    
    /// if hideDockIcon is enabled, temporarily enable it whenever
    /// we have this window open
    
    .onChange(of: controlActiveState) {
      switch controlActiveState {
      case .key, .active:
        if (AppState.shared.hideDockIcon) {
          NSApp.setActivationPolicy(.regular)
        }
      case .inactive:
        break
      @unknown default:
        break
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
      if let window = newValue.object as? NSWindow {
        let thisWindowIdentifier = NSUserInterfaceItemIdentifier("recordings-window")
        if window.identifier == thisWindowIdentifier {
          if (AppState.shared.hideDockIcon) {
            Logger.sampleLibrary.debug("hiding dock icon")
            NSApp.setActivationPolicy(.accessory)
          }
        }
      }
    }
    
    
    .searchable(
      text: $viewModel.searchText,
      tokens: $viewModel.currentSearchTokens,
      //      suggestedTokens: .constant(viewModel.suggestedSearchTokens),
      placement: .sidebar,
      prompt: Text("Type to search")
    ) { token in
      Label("\(token.tag)", systemImage: "number")
    }
    .searchSuggestions {
      ForEach(viewModel.suggestedSearchTokens, id: \.self) { suggestion in
        Label("\(suggestion.tag)", systemImage: "number")
          .searchCompletion(suggestion)
      }
    }
    .onReceive(
      NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
    ) { _ in
      // window is closed, stop audio playback
      if viewModel.slAudioPlayer.isPlaying {
        viewModel.slAudioPlayer.forcePause()
      }
    }
  }
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
    .frame(width: 1000, height: 600)
}
