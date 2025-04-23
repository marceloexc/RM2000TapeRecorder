import SettingsAccess
import SwiftUI

@main
struct RM2000TapeRecorderApp: App {
	@StateObject var appState = AppState.shared
	@StateObject var sampleStorage = SampleStorage.shared
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	@StateObject private var recordingState = TapeRecorderState()

	var body: some Scene {
		MenuBarExtra("RP2000 Portable", systemImage: "recordingtape") {
			MenuBarView()
				.environmentObject(appDelegate.recordingState)
				.environmentObject(sampleStorage)
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
		WindowGroup("Inspector", id: "inspector") {
			InspectorView()
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
