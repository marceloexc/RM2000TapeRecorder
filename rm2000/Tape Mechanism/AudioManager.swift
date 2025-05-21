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
	
	var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
	private let writeQueue = DispatchQueue(label: "audio.writer.queue")
	private var audioFile: AVAudioFile?
	private let encodingParams: [String: Any] = [
		AVFormatIDKey: kAudioFormatLinearPCM,
		AVSampleRateKey: 48000.0,
		AVNumberOfChannelsKey: 2,
		AVLinearPCMBitDepthKey: 16,
		AVLinearPCMIsFloatKey: false,
		AVLinearPCMIsBigEndianKey: false,
		AVLinearPCMIsNonInterleaved: false
	]
	
	func setupAudioWriter(fileURL: URL) throws {
		audioFile = try AVAudioFile(forWriting: fileURL, settings: encodingParams, commonFormat: .pcmFormatFloat32, interleaved: false)
	}
  
	func writeSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
		writeQueue.async {
			guard sampleBuffer.isValid else {
				Logger.audioManager.warning("Invalid sample buffer or conversion failed")
				return
			}
			
			try? sampleBuffer.withAudioBufferList { audioBufferList, blockBuffer in
				guard let description = sampleBuffer.formatDescription?.audioStreamBasicDescription,
							let format = AVAudioFormat(standardFormatWithSampleRate: description.mSampleRate, channels: description.mChannelsPerFrame),
							let samples = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
							else { return }
				self.pcmBufferHandler?(samples)
				do {
					try self.audioFile?.write(from: samples)
					// post the audiolevel into the wild for observing
					let currentAudioLevel = self.getAudioLevel(from: samples)

					DispatchQueue.main.async {
						NotificationCenter.default.post(name: .audioLevelUpdated, object: nil, userInfo: ["level": currentAudioLevel])
					}
				} catch {
					Logger.audioManager.error("Couldn't write samples: \(error.localizedDescription)")
				}
			}
		}
	}
  
	func getAudioLevel(from samples: AVAudioPCMBuffer) -> Float {
		
		// calculate root mean square
		// https://stackoverflow.com/a/43789556
		let channelCount = Int(samples.format.channelCount)
		let arraySize = samples.frameLength
		let bufferPointer = samples.floatChannelData!
		
		var sumOfSquares: Float = 0.0
		var sampleCount: Int = 0
		
		// process all channels
		for channel in 0..<channelCount {
			let channelData = bufferPointer[channel]
			
			// sum square of all samples
			for frame in 0..<Int(arraySize) {
				let sample = channelData[frame]
				sumOfSquares += sample * sample
				sampleCount += 1
			}
		}
		
		// do not divide by zero
		guard sampleCount > 0 else { return 0.0 }
		
		// calculate RMS
		let rms = sqrt(sumOfSquares / Float(sampleCount))
		
		return pow(rms, 0.3)
	}
	
	func stopAudioWriter() {
		writeQueue.sync { [weak self] in
			if #available(macOS 15.0, *) {
				// close func barely added to macos15? wtf?
				try? self?.audioFile?.close()
			}
			self?.audioFile = nil
		}
	}
	
	deinit {
		// just to be sure
		try? self.audioFile = nil
	}
}

extension Notification.Name {
	static let audioLevelUpdated = Notification.Name("audioLevelUpdated")
}
