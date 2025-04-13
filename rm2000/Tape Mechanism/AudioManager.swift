//
//  AudioManager.swift
//  rm2000
//
//  Created by Marcelo Mendez on 9/23/24.
//

import Foundation
import AVFAudio
import OSLog

class AudioManager {
	
	func setupAudioWriter(fileURL: URL) throws {
		audioFile = try AVAudioFile(forWriting: fileURL, settings: encodingParams, commonFormat: .pcmFormatFloat32, interleaved: false)
	}
  
	func writeSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
		guard sampleBuffer.isValid, let samples = sampleBuffer.asPCMBuffer else {
			Logger.audioManager.warning("Invalid sample buffer or conversion failed")
			return
		}
		
		// post the audiolevel into the wild for observing
		let currentAudioLevel = getAudioLevel(from: sampleBuffer)
		NotificationCenter.default.post(name: .audioLevelUpdated, object: nil, userInfo: ["level": currentAudioLevel])
		
		do {
			try audioFile?.write(from: samples)
		} catch {
			Logger.audioManager.error("Couldn't write samples: \(error.localizedDescription)")
		}
	}
  
	func getAudioLevel(from sampleBuffer: CMSampleBuffer) -> Float {
		guard sampleBuffer.isValid, let samples = sampleBuffer.asPCMBuffer else {
			Logger.audioManager.warning("Invalid sample buffer or conversion failed")
			return 0.0
		}
		
		// calculate root mean square
		let channelCount = Int(samples.format.channelCount)
		let frameLength = samples.frameLength
		let bufferPointer = samples.floatChannelData!
		
		var sumOfSquares: Float = 0.0
		var sampleCount: Int = 0
		
		// process all channels
		for channel in 0..<channelCount {
			let channelData = bufferPointer[channel]
			
			// sum square of all samples
			for frame in 0..<Int(frameLength) {
				let sample = channelData[frame]
				sumOfSquares += sample * sample
				sampleCount += 1
			}
		}
		
		// do not divide by zero
		guard sampleCount > 0 else { return 0.0 }
		
		// calculate RMS
		let rms = sqrt(sumOfSquares / Float(sampleCount))
		
		return rms
	}
	func stopAudioWriter() {
		audioFile = nil
	}
	
	private var audioFile: AVAudioFile?
  
	private let encodingParams: [String: Any] = [
		AVFormatIDKey: kAudioFormatMPEG4AAC,
		AVSampleRateKey: 48000,
		AVNumberOfChannelsKey: 2,
		AVEncoderBitRateKey: 128000
	]
}

extension Notification.Name {
	static let audioLevelUpdated = Notification.Name("audioLevelUpdated")
}
