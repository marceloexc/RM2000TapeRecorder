import Foundation
import SwiftUI
import OSLog

struct MenuBarView: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	@EnvironmentObject private var sampleStorage: SampleStorage
	@Environment(\.openWindow) private var openWindow
	
	private var appDelegate = AppKitWindowManagerDelegate()
	
	var body: some View {
		Text("RM2000 Public Beta")
		Divider()
		Button("Open") {
			appDelegate.showMainWindow()
		}
		
		if recordingState.status == .recording {
			ElapsedTime(textString: $recordingState.elapsedTimeRecording)
		}
		
		Button(recordingState.status == .recording ? "Stop Recording" : "Start Recording") {
			if recordingState.status == .recording {
				Logger.sharedStreamState.info("Changing state in the menubar")
				recordingState.stopRecording()
			} else {
				recordingState.startRecording()
			}
		}
		Button("Print Debug information to console") {
			print("\(sampleStorage.UserDirectory.files)")
		}
		Divider()
		Button("Quit RM2000") {
			NSApplication.shared.terminate(nil)
		}.keyboardShortcut("q")
	}
}

struct ElapsedTime: View {
	@Binding var textString: TimeInterval

	var body: some View {
		Text(textString.description)
	}
}
