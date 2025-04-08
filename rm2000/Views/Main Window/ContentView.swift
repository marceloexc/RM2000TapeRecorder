import OSLog
import SwiftUI

struct ContentView: View {
	@Environment(\.openWindow) var openWindow
	@EnvironmentObject private var recordingState: TapeRecorderState

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

				if recordingState.isRecording {
					ActiveRecordButton(onPress: stopRecording)
				} else {
					StandbyRecordButton(onPress: startRecording)
				}

			}
			
			.sheet(isPresented: $recordingState.showRenameDialogInMainWindow) {
				if let newRecording = recordingState.currentActiveRecording {
					EditSampleView(recording: newRecording) { FileRepresentable, SampleMetadata in
						
						// TODO - trainwreck. if i already have to pass in the shared.userdirectory, then this probably belongs in samplestorage itself, not sampledirectory
						SampleStorage.shared.UserDirectory.applySampleEdits(for: FileRepresentable, with: SampleMetadata)
						recordingState.showRenameDialogInMainWindow = false
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
