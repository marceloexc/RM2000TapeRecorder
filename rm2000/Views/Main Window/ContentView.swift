import OSLog
import SettingsAccess
import SwiftUI

struct ContentView: View {
  @Environment(\.openWindow) var openWindow
  @EnvironmentObject private var recordingState: TapeRecorderState
  @EnvironmentObject private var storeManager: StoreManager
  @Environment(\.controlActiveState) private var controlActiveState

  @Environment(\.openSettingsLegacy) private var openSettingsLegacy

  @State private var showTrialExpiredSheet: Bool = false

  var body: some View {
    ZStack {
      Image("BodyBackgroundTemp")
        .scaledToFill()
        .ignoresSafeArea(.all)  // extend under the titlebar
      VStack(spacing: 10) {
        LCDScreenView()
          .frame(height: 225)
          .padding(.top, -45)

        HStack(spacing: 5) {
          UtilityButtons()
        }
        .padding(.top, -5)

        if recordingState.status == .recording {
          ActiveRecordButton(onPress: stopRecording)
        } else {
          StandbyRecordButton(onPress: startRecording)
        }

      }

      .sheet(isPresented: $recordingState.showRenameDialogInMainWindow) {
        if let newRecording = recordingState.currentActiveRecording {
          EditSampleView(recording: newRecording) {
            FileRepresentable, SampleMetadata, SampleEditConfiguration in

            // TODO - trainwreck. if i already have to pass in the shared.userdirectory, then this probably belongs in samplestorage itself, not sampledirectory
            SampleStorage.shared.UserDirectory.applySampleEdits(
              to: FileRepresentable, for: SampleMetadata,
              with: SampleEditConfiguration)
            recordingState.showRenameDialogInMainWindow = false
          }
          .frame(minWidth: 420, maxWidth: 500, minHeight: 320)
          .presentationBackground(.thinMaterial)
        }
      }
      .sheet(isPresented: $showTrialExpiredSheet) {
        
        VStack(spacing: 16) {
          Text("Trial Expired")
            .font(.title)
            .bold()
          Text("Please purchase the full version to continue using the app.")
          Button("Buy Now") {
            try? openSettingsLegacy()
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
      }
    }
    .onChange(of: storeManager.trialStatus) { newStatus in
      if newStatus == .expired {
        showTrialExpiredSheet = true
      } else {
        showTrialExpiredSheet = false
      }
    }
    .onAppear {
      if storeManager.trialStatus == .expired {
        showTrialExpiredSheet = true
      }
    }
    /// if hideDockIcon is enabled, temporarily enable it whenever
    /// we have this window open
    
    .onChange(of: controlActiveState) {
      switch controlActiveState {
      case .key:
        if (AppState.shared.hideDockIcon) {
          NSApp.setActivationPolicy(.regular)
        }

      case .inactive:
        break
      case .active:
        break
      @unknown default:
        break
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
      if let window = newValue.object as? NSWindow {
        let thisWindowIdentifier = NSUserInterfaceItemIdentifier("mainWindow")
        if window.identifier == thisWindowIdentifier {
          if (AppState.shared.hideDockIcon) {
            Logger.mainWindow.debug("Hiding dock icon")
            NSApp.setActivationPolicy(.accessory)
          }
        }
      }
    }
  }

  private func startRecording() {
    recordingState.startRecording()
  }

  private func stopRecording() {
    recordingState.stopRecording()
  }

}

#Preview("Main Window") {
  ContentView()
    .environmentObject(TapeRecorderState())
}
