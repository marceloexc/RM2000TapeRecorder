// public facing functions for the main Recording audio logic
// "tape mechanism" probably isn't the smartest thing to name a piece of code, but its cute
// so ill keep it like this

import Foundation
import OSLog
import CoreMedia
import ScreenCaptureKit

protocol TapeRecorderDelegate: AnyObject {
	func tapeRecorderDidStartRecording(_ recorder: TapeRecorder)
	func tapeRecorderDidStopRecording(_ recorder: TapeRecorder)
	func tapeRecorder(_ recorder: TapeRecorder, didEncounterError error: Error)
}

// MARK: - TapeRecorder

class TapeRecorder: NSObject {
  
	// properties
  
	weak var delegate: TapeRecorderDelegate?
  
	private let streamManager: StreamManager
	private let audioManager: AudioManager
  
	private(set) var isRecording: Bool = false
  
	// initialization
  
	override init() {
		self.streamManager = StreamManager()
		self.audioManager = AudioManager()
		super.init()
	  
		self.streamManager.delegate = self
	}
  
	// both public functions - starting and stopping
  
	func startRecording(filename: String, directory: String) async {
		guard !isRecording else {
			Logger.tapeRecorder.warning("Recording is already in progress")
			return
		}
	  
		let directoryURL = URL(fileURLWithPath: directory)
		let fileURL = directoryURL.appendingPathComponent(filename)
		
		do {
			try await streamManager.setupAudioStream()
			try audioManager.setupAudioWriter(fileURL: fileURL)
			try streamManager.startCapture()
		  
			isRecording = true
			delegate?.tapeRecorderDidStartRecording(self)
			Logger.tapeRecorder.info("Started recording to file: \(fileURL)")
		} catch {
			delegate?.tapeRecorder(self, didEncounterError: error)
			Logger.tapeRecorder.error("Failed to start recording: \(error.localizedDescription)")
		}
	}
  
	func stopRecording() {
		guard isRecording else {
			Logger.tapeRecorder.warning("No active recording to stop")
			return
		}
	  
		streamManager.stopCapture()
		audioManager.stopAudioWriter()
	  
		isRecording = false
		delegate?.tapeRecorderDidStopRecording(self)
		Logger.tapeRecorder.info("Stopped recording")
	}
}

extension TapeRecorder: StreamManagerDelegate {
	func streamManager(_ manager: StreamManager, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
		guard type == .audio else { return }
	  
		audioManager.writeSampleBuffer(sampleBuffer)
	}
  
	func streamManager(_ manager: StreamManager, didStopWithError error: Error) {
		stopRecording()
		delegate?.tapeRecorder(self, didEncounterError: error)
	}
}
