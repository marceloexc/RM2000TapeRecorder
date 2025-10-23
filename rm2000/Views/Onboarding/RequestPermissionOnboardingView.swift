import OSLog
import SwiftUI

struct RequestPermissionOnboardingView: View {
  private let streamManager = SCStreamManager()

  var body: some View {
    VStack(spacing: 50) {
      VStack {
        Text("Screen Recording Access Required")
          .font(.custom("InstrumentSerif-Regular", size: 50))
          .kerning(-2.0)
          .foregroundStyle(
            LinearGradient(
              stops: [
                .init(color: Color(hex: 0xdfdfdf), location: 0),
                .init(color: Color(hex: 0xc0c0c0), location: 1),
              ], startPoint: .bottom, endPoint: .top)
          )
          .shadow(color: .black, radius: 1, y: 1)

        Text(
          "Without granting permission, RM2000 Tape Recorder won't be able to record audio."
        )
        .font(.custom("LucidaGrande", size: 12))
        .foregroundStyle(Color(.white))
      }

      Button {
        Task {
          await invokeRecordingPermission()
        }
      } label: {
        Text("Grant Permission")
      }
      .controlSize(.extraLarge)
      .buttonStyle(.borderedProminent)
      .tint(.red)

    }
    .frame(width: 700, height: 550)
    .background(
      RadialGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: 0x572019), location: 0.01),
          //            .init(color: Color(hex: 0x862618), location: 0.10),
          .init(color: Color(hex: 0x00010f), location: 0.99),
        ]),
        center: .center,
        startRadius: 0,
        endRadius: 400
      )
    )
    .onAppear {
      AppState.shared.hasCompletedOnboarding = true
      Logger.appState.info("Set hasCompletedOnboarding to true")
    }
  }

  private func invokeRecordingPermission() async {
    do {
      try await streamManager.setupAudioStream()
    } catch {
      Logger.viewModels.error("Recording permission declined")

      // https://stackoverflow.com/a/78740238
      // i seriously have to use NSAlert for this?

      let alert = showPermissionAlert()
      if alert.runModal() == .alertFirstButtonReturn {
        NSWorkspace.shared.open(
          URL(
            string:
              "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
          )!)
      }
    }
  }

  private func showPermissionAlert() -> NSAlert {
    let alert = NSAlert()
    alert.messageText = "Permission Request"
    alert.alertStyle = .informational
    alert.informativeText =
      "RM2000 requires permission to record the screen in order to grab system audio."
    alert.addButton(withTitle: "Open System Settings")
    return alert
  }
}

#Preview {
  RequestPermissionOnboardingView()
}
