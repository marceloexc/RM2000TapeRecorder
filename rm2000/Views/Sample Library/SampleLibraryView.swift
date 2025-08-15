import Combine
import Foundation
import OSLog
import SwiftUI
import RenderMeThis

extension ToolbarItemPlacement {
  static let favoritesBar = accessoryBar(id: "com.example.favorites")
}

struct SampleLibraryView: View {
  @StateObject private var viewModel: SampleLibraryViewModel
  @Environment(\.openURL) private var openURL
  @Environment(\.controlActiveState) private var controlActiveState
  @AppStorage("detailViewType") var detailViewType: DetailViewType = .list
  @State private var isAudioPlaying = false

  init() {
    _viewModel = StateObject(wrappedValue: SampleLibraryViewModel())
  }

  var body: some View {
    NavigationSplitView {
      if #available(macOS 14.0, *) {
        SidebarView(viewModel: viewModel)
          .toolbar(removing: .sidebarToggle)
          .toolbar(id: "rm2000.sidebar", content: {
            ToolbarItem(id: "rm2000.sidebar") {
              SidebarButton()
            }.customizationBehavior(.disabled)
          })
          .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
      } else {
        SidebarView(viewModel: viewModel)
          .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
      }
    } detail: {
      DetailView(viewModel: viewModel, currentView: $detailViewType)
        .navigationSplitViewColumnWidth(min: 500, ideal: 500)
        .toolbar(id: "rm2000.main-toolbar", content: mainToolbarContent)
        .toolbar(id: "rm2000.favorites-toolbar", content: accessoryBarContent)
    }
    .inspector(isPresented: $viewModel.showInspector) {
      InspectorView(viewModel: viewModel)
        .toolbar(id: "rm2000.inspector.toolbar", content: inspectorToolbarContent)
        .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
    }
    .navigationTitle("Sample Library")
    .navigationSubtitle("\(viewModel.filteredSamples.count) Samples")
    .onChange(of: controlActiveState) {
      switch controlActiveState {
      case .key, .active:
        if (AppState.shared.hideDockIcon) {
          Logger.sampleLibrary.debug("temporarily unhiding dock icon")
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
    .onReceive(viewModel.slAudioPlayer.$isPlaying) {
        isAudioPlaying = $0
    }
    .onReceive(
      NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
        // window is closed, stop audio playback
        if let window = newValue.object as? NSWindow {
          let thisWindowIdentifier = NSUserInterfaceItemIdentifier("recordings-window")
          if window.identifier == thisWindowIdentifier {
            viewModel.slAudioPlayer.forcePause()
          }
        }
      }
//      .debugCompute()
  }
  
  @ToolbarContentBuilder
  func mainToolbarContent() -> some CustomizableToolbarContent {
    ToolbarItem(id: "rm2000.share.button", placement: .primaryAction) {
      ShareSampleButton(selectedItems: viewModel.selectedSamples.map { FileRepresentableItemModel(file: $0.self) } )
    }
//    ToolbarItem(id: "rm2000.import", placement: .primaryAction) {
//      ImportSampleButton()
//    }
    ToolbarItem(id: "rm2000.open-in-finder-button", placement: .primaryAction)
    {
      OpenInFinderButton()
    }
    ToolbarItem(id: "rm2000.view-options", placement: .primaryAction) {
      ViewModeButton(selection: $detailViewType)
    }
  }
  
  @ToolbarContentBuilder
  func accessoryBarContent() -> some CustomizableToolbarContent {
    let isDisabled = viewModel.selectedSamples.isEmpty && !isAudioPlaying
    AudioPlayerToolbar(
        player: viewModel.slAudioPlayer,
        isDisabled: isDisabled
    )
  }
  
  @ToolbarContentBuilder
  func inspectorToolbarContent() -> some CustomizableToolbarContent {
    ToolbarItem(id: "rm2000.spacer") {
      Spacer()
    }
    ToolbarItem(id: "rm2000.inspector.button", placement: .primaryAction) {
      Button {
        viewModel.showInspector.toggle()
      } label: {
        Label("Inspector", systemImage: "info.circle.fill")
          .foregroundStyle(.cyan)
      }
    }
    
  }
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
    .frame(width: 900, height: 600)
}
