import Foundation
import OSLog
import SwiftUI

struct SettingsView: View {

	@EnvironmentObject private var appState: AppState
	@State private var workingDirectory: URL? = nil
	@State private var autostartAtLogin = false
	@State private var minimizeToToolbar = false
	@State private var selectedTab = "General"

	var body: some View {
		TabView(selection: $selectedTab) {
			GeneralTabView()
				.tabItem {
					Label("General", systemImage: "gear")
				}
				.padding()
				.frame(width: 450)
				.tag("General")
			
			RecordingTabView(workingDirectory: $workingDirectory)
				.tabItem {
					Label("Recording", systemImage: "recordingtape.circle.fill")
				}
				.padding()
				.frame(width: 450)
				.tag("Recording")
		}
		.onAppear {
			workingDirectory = appState.sampleDirectory
		}
	}

	private func autoStartAtLogin() {
		Logger.viewModels.warning("Not implemented yet")
	}
}

#Preview {
	SettingsView()
		.environmentObject(AppState.shared)
}
