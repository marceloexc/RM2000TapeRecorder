import SwiftUI
import OSLog

class TapeRecorderState: ObservableObject, TapeRecorderDelegate {
	static let shared = TapeRecorderState()
	@Published var status: RecordingState = .idle
	@Published var currentSampleFilename: String?
	@Published var showRenameDialogInMainWindow: Bool = false
	@Published var currentActiveRecording: TemporaryActiveRecording?
	@Published var elapsedTimeRecording: TimeInterval = 0
	@AppStorage("sample_record_audio_format") var sampleRecordAudioFormat: AudioFormat = .mp3
	private var timer: Timer?
	let recorder = TapeRecorder()
	
	init() {
		recorder.delegate = self
	}
	
	@MainActor
	func startRecording() {
		Task {
			await MainActor.run {
				self.status = .recording
			}
			startTimer()
			let newRecording = TemporaryActiveRecording()
			currentSampleFilename = newRecording.fileURL.lastPathComponent
			self.currentActiveRecording = newRecording
			NSApp.dockTile.badgeLabel = "REC"
			
			await recorder.startRecording(to: newRecording.fileURL)
		}
	}
	
	func stopRecording() {
		recorder.stopRecording()
		timer?.invalidate()
		timer = nil
		showRenameDialogInMainWindow = true
		NSApp.dockTile.badgeLabel = nil
		Task {
			do {
				await AppState.shared.closeHUDWindow() // ensure hud window is closed
				// TODO - this is very hacky
			}
		}
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
			self.status = .idle
		}
	}
	
	func tapeRecorder(_ recorder: TapeRecorder, didEncounterError error: Error) {
		Task { @MainActor in
			self.status = .idle
			Logger.sharedStreamState.error("Recording error: \(error.localizedDescription)")
			// You might want to update UI or show an alert here
		}
	}
}
