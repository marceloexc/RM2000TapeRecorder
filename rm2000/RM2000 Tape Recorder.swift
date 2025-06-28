import SettingsAccess
import SwiftUI

@main
struct RM2000TapeRecorderApp: App {
	@StateObject var appState = AppState.shared
	@StateObject var sampleStorage = SampleStorage.shared
	@StateObject private var recordingState = TapeRecorderState.shared
	@NSApplicationDelegateAdaptor(AppKitWindowManagerDelegate.self) var appDelegate

	var body: some Scene {
		MenuBarExtra {
      MenuBarView(appDelegate: appDelegate)
				.environmentObject(appDelegate.recordingState)
				.environmentObject(sampleStorage)
		} label: {
			Image("RecordingTapeBlackFlipped")
		}
		.menuBarExtraStyle(.window)

		Window("Recordings", id: "recordings-window") {
			SampleLibraryView()
				.environmentObject(sampleStorage)
		}
		Window("Getting Started", id: "onboarding") {
      OnboardingView(pages: OnboardingStep.fullOnboarding)
				.environmentObject(appState)
		}
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
		
		Settings {
			SettingsView()
				.environmentObject(appState)
				.environmentObject(recordingState)
		}
    .commands {
      CommandGroup(after: .help) {
        Button("Email Developer (Support)") {
          let mailtoURL = URL(string: "mailto:marcelomendez@live.com")!
          NSWorkspace.shared.open(mailtoURL)
        }
        Button("Open Source Acknowledgements") {
          guard let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf") else {
            return
          }
          NSWorkspace.shared.open(url)
        }
      }
    }
	}
}
