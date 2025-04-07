import SwiftUI
import OSLog

class TapeRecorderState: ObservableObject, TapeRecorderDelegate {
	@Published var isRecording: Bool = false
	@Published var currentSampleFilename: String?
	@Published var showRenameDialogInMainWindow: Bool = false
	@Published var currentActiveRecording: TemporaryActiveRecording?
	@Published var elapsedTimeRecording: TimeInterval = 0
	
	private var timer: Timer?
	
	let recorder = TapeRecorder()
	
	init() {
		recorder.delegate = self
	}
	
	@MainActor
	func startRecording() {
		Task {
			await MainActor.run {
				self.isRecording = true
			}
			startTimer()
			let newRecording = TemporaryActiveRecording()
			currentSampleFilename = newRecording.fileURL.lastPathComponent
			self.currentActiveRecording = newRecording 
			
			await recorder.startRecording(to: newRecording.fileURL)
		}
	}
	
	func stopRecording() {
		recorder.stopRecording()
		timer?.invalidate()
		timer = nil
		showRenameDialogInMainWindow = true
		Logger.sharedStreamState.info("showing edit sample sheet")
	}
	
	private func startTimer() {
		self.elapsedTimeRecording = 0
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			self.elapsedTimeRecording += 1
		}
	}
	
	func tapeRecorderDidStartRecording(_ recorder: TapeRecorder) {
		// This might not be necessary if we set isRecording to true in startRecording
	}
	
	func tapeRecorderDidStopRecording(_ recorder: TapeRecorder) {
		Task { @MainActor in
			self.isRecording = false
		}
	}
	
	func tapeRecorder(_ recorder: TapeRecorder, didEncounterError error: Error) {
		Task { @MainActor in
			self.isRecording = false
			Logger.sharedStreamState.error("Recording error: \(error.localizedDescription)")
			// You might want to update UI or show an alert here
		}
	}
}
