import SwiftUI

struct AudioPlayerToolbar: CustomizableToolbarContent {
  @State private var isShowingPopover: Bool = false
  @ObservedObject var player: SLAudioPlayer
  let isDisabled: Bool
  
  var body: some CustomizableToolbarContent {
    ToolbarItem(id: "rm2000.playpause", placement: .favoritesBar) {
      Button {
        player.playPause()
      } label: {
        Image(
          systemName: player.isPlaying
          ? "pause.fill" : "play.fill")
      }
      .contentTransition(.symbolEffect(.replace))
      .keyboardShortcut(.space, modifiers: [])
      .frame(width: 20)
      .disabled(isDisabled)
    }
    
    ToolbarItem(id: "rm2000.volume", placement: .favoritesBar) {
      Button {
        self.isShowingPopover = true
      } label: {
        ZStack {
          // Muted
          Image(systemName: "speaker.slash.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.red, .secondary)
            .opacity(player.setVolume == 0 ? 1 : 0)
            .animation(Animation.easeInOut(duration: 0.15), value: player.setVolume)

          // not muted
          Image(systemName: "speaker.wave.3.fill", variableValue: Double(player.setVolume))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.primary, .primary)
            .opacity(player.setVolume > 0 ? 1 : 0)
            .animation(Animation.easeInOut(duration: 0.15), value: player.setVolume)
        }
      }
      .frame(width: 20)
      .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
        VStack {
          Slider(
              value: Binding(
                  get: { player.setVolume },
                  set: { player.setVolume = $0 }
              ),
              in: 0...1
          )
          .frame(width: 200)
          Text("\(player.setVolume.isFinite ? String(format: "%.1f", player.setVolume * 100) : "0")% Volume")
        }
        .padding()
      }
    }
    
    ToolbarItem(id: "rm2000.repeat-toggle", placement: .favoritesBar) {
      Toggle(isOn: $player.isRepeat) {
        Label("Repeat", systemImage: "repeat")
      }
    }
    
    ToolbarItem(id: "rm2000.duration", placement: .favoritesBar) {
      Text(player.currentTime.formattedDuration)
        .frame(width: 45, alignment: .leading)
        .disabled(isDisabled)
      
    }
    ToolbarItem(id: "rm2000.slider", placement: .favoritesBar) {
      Slider(
        value: Binding(
          get: { player.currentTime },
          set: { player.seekTo(time: $0) }
        ),
        in: 0...player.duration
      )
      .disabled(isDisabled)
      
    }
    
    ToolbarItem(id: "rm2000.divider", placement: .favoritesBar) {
      Divider()
    }
    
    ToolbarItem(id: "rm2000.autoplay.string", placement: .favoritesBar) {
      Text("Autoplay")
    }
    
    ToolbarItem(id: "rm2000.autoplay-toggle", placement: .favoritesBar) {
      Toggle(
        "Autoplay",
        isOn: $player.isAutoplay
      ).toggleStyle(.switch)
    }
  }
  
  
}

#Preview {
  SampleLibraryView()
    .environmentObject(SampleStorage.shared)
    .frame(width: 900, height: 600)
}
