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
			MenuBarView()
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
		WindowGroup("Welcome", id: "onboarding") {
			OnboardingView(viewModel: OnboardingViewModel())
				.environmentObject(appState)
		}
		.windowResizability(.contentSize)
		.windowStyle(.hiddenTitleBar)
		
		Settings {
			SettingsView()
				.environmentObject(appState)
				.environmentObject(recordingState)
		}
	}
}
