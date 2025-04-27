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
		.windowResizability(.contentSize)
		.windowStyle(.hiddenTitleBar)

		WindowGroup("HUD Window", id: "hud") {
			HUDWindowView()
				.frame(width: 400, height: 250)
				.background(.clear)
				.environmentObject(recordingState)
		}
		.windowStyle(.hiddenTitleBar)
		.windowResizability(.contentSize)
		
		Settings {
			SettingsView()
				.environmentObject(appState)
				.environmentObject(recordingState)
		}
	}
}
