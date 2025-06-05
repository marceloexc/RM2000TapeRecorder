import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftUI

struct GeneralTabView: View {

  var body: some View {
    Form {
      LaunchAtLogin.Toggle()
      KeyboardShortcuts.Recorder(
        "Quick Recording Hotkey", name: .recordGlobalShortcut)
    }
  }
}

#Preview {
  SettingsView()
    .environmentObject(AppState.shared)
}
