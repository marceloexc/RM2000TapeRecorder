import SwiftUI

struct AudioPlayerToolbar: CustomizableToolbarContent {
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
      .disabled(isDisabled)
    }
    ToolbarItem(id: "rm2000.duration", placement: .favoritesBar) {
      Text(player.currentTime.formattedDuration)
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
  
  
}
