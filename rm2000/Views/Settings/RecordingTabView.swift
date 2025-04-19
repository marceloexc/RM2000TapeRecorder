import SwiftUI
import OSLog

struct RecordingTabView: View {
	@State private var selectedFileType = AudioFormat.aac
	@State private var showFileChooser: Bool = false
	@Binding var workingDirectory: URL?
	@EnvironmentObject var appState: AppState
	
    var body: some View {
			Form {
				HStack {
					GroupBox(
						label:
							Label("Saved Directory", systemImage: "books.vertical")
					) {
						HStack {
							Text(
								"Currently set to \"\(workingDirectory?.lastPathComponent ?? "nil")\""
							)
							.font(.caption)
							
							Spacer()
							
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
				}
				
				
				GroupBox(
					label:
						Label("Recording", systemImage: "recordingtape")
				) {
					HStack {
						Text("Audio Format")
							.font(.caption)
						
						Spacer()
						Picker("Sample File Type", selection: $selectedFileType) {
							Text("AAC").tag(AudioFormat.aac)
							Text("MP3").tag(AudioFormat.mp3).disabled(true)
							Text("WAV").tag(AudioFormat.wav).disabled(true)
							Text("FLAC").tag(AudioFormat.flac).disabled(true)
							
						}
						.frame(width:200)
						.labelsHidden() //misbehaves otherwise
						.pickerStyle(.segmented)
						.clipped()
						.onChange(of: selectedFileType) { newValue in
							Logger.appState.info("New audio format of \(newValue) selected")
							selectedFileType = newValue
						}
					}
				}
			}
    }
}

#Preview {
	RecordingTabView(workingDirectory: .constant(URL(string: "file:///Users/user/Documents")!))
		.environmentObject(AppState.shared)
		.padding()
		.frame(width: 350)
}

