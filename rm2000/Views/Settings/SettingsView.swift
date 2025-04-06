import Foundation
import OSLog
import SwiftUI

struct SettingsView: View {

	@EnvironmentObject private var appState: AppState
	@State private var selectedFileType = AudioFormat.aac
	@State private var workingDirectory: URL? = nil
	@State private var autostartAtLogin = false
	@State private var minimizeToToolbar = false
	@State private var selectedTab = "General"
	@State private var showFileChooser: Bool = false

	var body: some View {
		TabView(selection: $selectedTab) {
			Form {
				GroupBox(
					label:
						Label("Recording", systemImage: "recordingtape")
				) {
					Picker("Sample File Type", selection: $selectedFileType) {
						Text("AAC").tag(AudioFormat.aac)
						Text("Lol thats about it").tag(AudioFormat.mp3).disabled(true)
						Text("Ill try to get at least MP3 support by next week").tag(AudioFormat.wav).disabled(true)

					}
					.pickerStyle(MenuPickerStyle())
					.onChange(of: selectedFileType) { newValue in
						selectedFileType = newValue
					}
					.pickerStyle(.menu)
				}

				GroupBox(
					label:
						Label("Saved Directory", systemImage: "books.vertical")
				) {
					HStack {
						Text(
							"Currently set to \"\(workingDirectory?.lastPathComponent ?? "nil")\""
						)
						.font(.caption)

						Button("Browse") {
							showFileChooser = true
						}
						.fileImporter(
							isPresented: $showFileChooser,
							allowedContentTypes: [.directory]
						) { result in
							switch result {
							case .success(let directory):
								
								// get security scoped bookmark
								guard directory.startAccessingSecurityScopedResource() else {
									Logger.appState.error("Could not get security scoped to the directory \(directory)")
									return
								}
								appState.sampleDirectory = directory
								workingDirectory = directory
								Logger.appState.info(
									"Settings set new sample directory to \(directory)"
								)
							case .failure(let error):
								Logger.appState.error(
									"Could not set new sampleDirectory from settings view: \(error)"
								)
							}
						}
					}
				}
				Section {
					Toggle("Start at Login", isOn: $autostartAtLogin)
						.onChange(of: autostartAtLogin) { newValue in
							autoStartAtLogin()
						}
					Toggle("Minimize to Toolbar", isOn: $minimizeToToolbar)
						.disabled(!autostartAtLogin)
				}

				Section {
					Toggle("Show File Extensions", isOn: .constant(true))
					Toggle("Keep unsaved samples", isOn: .constant(true))
				}
			}
			.padding()
			.frame(width: 450)
			.tabItem {
				Label("General", systemImage: "gear")
			}
			.tag("General")
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
