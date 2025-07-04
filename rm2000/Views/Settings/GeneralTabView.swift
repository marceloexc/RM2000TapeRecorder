import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftUI

struct GeneralTabView: View {
  @State private var isDockHidden: Bool = AppState.shared.hideDockIcon

  var body: some View {
    VStack {
      GroupBox {
        Form {
          LaunchAtLogin.Toggle("Launch at Login")
            .toggleStyle(.switch)

          Section {

            Toggle(isOn: $isDockHidden) {
              Text("Hide Icon in Dock")
            }.toggleStyle(.switch)
              .onChange(of: isDockHidden) { _, newValue in
                AppState.shared.hideDockIcon = newValue
              }
          } footer: {
            //            Text("Use .")
            //              .font(.caption)
            //              .foregroundColor(.secondary)
          }

          KeyboardShortcuts.Recorder(
            "Quick Recording Hotkey", name: .recordGlobalShortcut)
        }
        .frame(maxWidth: .infinity)
      } label: {
        Text("General")
      }

      GroupBox {
        VStack {
          Button(
            action: {
              print("Hello world")
            },
            label: {
              Label {
                Text("Review on the App Store")
              } icon: {
                Image(systemName: "star")
              }
            })
        }
        .frame(maxWidth: .infinity)
      } label: {
        Text("Support")
      }
    }
  }
}

#Preview {
  SettingsView()
    .environmentObject(AppState.shared)
}
