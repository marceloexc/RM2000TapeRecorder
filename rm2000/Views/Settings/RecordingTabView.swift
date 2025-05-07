import SwiftUI
import OSLog

struct RecordingTabView: View {
	@State private var selectedFileType = AudioFormat.aac
	@State private var showFileChooser: Bool = false
	@Binding var workingDirectory: URL?
	@EnvironmentObject var appState: AppState
	@EnvironmentObject var recordingState: TapeRecorderState
	
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
							Text("MP3").tag(AudioFormat.mp3)
							Text("WAV").tag(AudioFormat.wav)
							Text("FLAC").tag(AudioFormat.flac)
						
						}
						.frame(width:200)
						.labelsHidden() //misbehaves otherwise
						.pickerStyle(.segmented)
						.clipped()
						.onChange(of: selectedFileType) { newValue in
							// Logger().debug("New audio format of \(newValue) selected")
							//
							// ^^^ uncomment that and you get this build error:
							// Failed to produce diagnostic for expression; please submit a bug report (https://swift.org/contributing/#reporting-bugs)
							// what the fuck?
							recordingState.sampleRecordAudioFormat = newValue
						}
					}
				}
				
			}.onAppear {
				selectedFileType = recordingState.sampleRecordAudioFormat
			}
    }
}

#Preview {
	RecordingTabView(workingDirectory: .constant(URL(string: "file:///Users/user/Documents")!))
		.environmentObject(AppState.shared)
		.environmentObject(TapeRecorderState())
		.padding()
		.frame(width: 350)
}

