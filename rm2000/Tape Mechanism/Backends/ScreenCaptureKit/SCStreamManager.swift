//
//  StreamManager.swift
//  rm2000
//
//  Created by Marcelo Mendez on 9/23/24.
//

import Foundation
import ScreenCaptureKit

class SCStreamManager: NSObject, SCStreamDelegate, @unchecked Sendable {
    
	weak var delegate: StreamManagerDelegate?
	private var stream: SCStream?
    
	func setupAudioStream() async throws {
		let streamConfiguration = SCStreamConfiguration()
		streamConfiguration.sampleRate = 48000
		streamConfiguration.channelCount = 2
		streamConfiguration.capturesAudio = true
		streamConfiguration.minimumFrameInterval = CMTime(seconds: 1.0 / 2.0, preferredTimescale: 600)
	  
		let availableContent = try await SCShareableContent.current
		guard let display = availableContent.displays.first(where: { $0.displayID == CGMainDisplayID() }) else {
			throw NSError(domain: "RecordingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Can't find display with ID \(CGMainDisplayID()) in sharable content"])
		}
	  
		let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
		stream = SCStream(filter: filter, configuration: streamConfiguration, delegate: self)
	}
  
	func startCapture() throws {
		guard let stream = stream else {
			throw NSError(domain: "RecordingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Stream not prepared"])
		}
		let audioProcessingQueue = DispatchQueue(label: "AudioProcessingQueue")
		try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioProcessingQueue)
		stream.startCapture()
	}
  
	func stopCapture() {
		stream?.stopCapture()
		try? stream?.removeStreamOutput(self, type: .audio)
		stream = nil
	}
  
	// make scstreamdelegate ghappy
  
	func stream(_ stream: SCStream, didStopWithError error: Error) {
		Task { @MainActor in
			delegate?.streamManager(self, didStopWithError: error)
		}
	}
}


extension SCStreamManager: SCStreamOutput {
	func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
		delegate?.streamManager(self, didOutputSampleBuffer: sampleBuffer, of: type)
	}
}
