import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftUI

struct GeneralTabView: View {
  @Environment(\.openURL) private var openURL
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
              requestReviewInAP()
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
  
  private func requestReviewInAP() {
    let url = "https://apps.apple.com/app/id6742876939?action=write-review"
    openURL(URL(string: url)!)
  }
}

#Preview {
  SettingsView()
    .environmentObject(AppState.shared)
}
