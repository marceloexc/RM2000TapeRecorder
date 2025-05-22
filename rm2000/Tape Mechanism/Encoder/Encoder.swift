import AVFoundation
import CoreMedia
import Foundation
import OSLog
import SFBAudioEngine
import CSFBAudioEngine

struct RMAudioConverter {
	static func convert(input: URL, output: URL, format: AudioFormat) async {
		do {
			let progress = Progress()
			try AudioConverter.convert(input, to: output)
			Logger().info("Conversion complete")
		} catch {
			Logger().error("Conversion failed: \(error.localizedDescription)")
		}
	}
}

struct EncodingConfig {
	let outputFormat: AudioFormat
	let outputURL: URL?
	let forwardsEndTime: CMTime?
	let reverseEndTime: CMTime?

	init(
		outputFormat: AudioFormat,
		outputURL: URL? = nil,
		forwardStartTime: CMTime?,
		backwardsEndTime: CMTime?
	) {
		self.outputFormat = outputFormat
		self.outputURL = outputURL
		self.forwardsEndTime = forwardStartTime
		self.reverseEndTime = backwardsEndTime
	}
}

enum EncodingInputType {
	case fileURL
	case pcmBuffer
	case existingSample
}

class Encoder {
	private(set) var isProcessing = false
	private(set) var sourceType: EncodingInputType

	private var sourceBuffer: AVAudioPCMBuffer?
	private var sourceURL: URL?

	private var needsTrimming: Bool = false

	init(fileURL: URL?) {
		self.sourceURL = fileURL
		self.sourceType = .fileURL
	}

	init(pcmBuffer: AVAudioPCMBuffer?) {
		self.sourceBuffer = pcmBuffer
		self.sourceType = .pcmBuffer
	}

	func encode(with config: EncodingConfig) async throws {

		if let forwardStart = config.forwardsEndTime,
			let backwardsEnd = config.reverseEndTime
		{
			needsTrimming = true
		}

		isProcessing = true

		switch sourceType {
		case .pcmBuffer:
			if needsTrimming {
				// awesome, we have the pcmBuffer already, just extract it, render as .caf, and then formatconvert
			}
		case .fileURL:

			if needsTrimming {
				Logger().debug("Sample needs trimming")

				guard let decoder = try? AudioDecoder(url: self.sourceURL!) else {
					Logger().error("Failed to init decoder for \(self.sourceURL!)")
					return
				}
				try decoder.open()
				let processingFormat = decoder.processingFormat
				print("Processing format: \(processingFormat), processing format length: \(decoder.length)")
				let frameCount = AVAudioFrameCount(decoder.length)
				guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: frameCount) else {
					Logger().error("Failed to get buffers from the decoder for \(self.sourceURL!)")
					return
				}
				
				try decoder.decode(into: buffer, length: frameCount)
				
				guard let trimmedBuffer = trimPCMBuffer(
					buffer: buffer,
					forwardsEndTime: config.forwardsEndTime!,
					reverseEndTime: config.reverseEndTime!
				) else {
					Logger().error("Failed to trim buffer")
					return
				}
				
				let trimmedSourceURL = sourceURL?.deletingLastPathComponent().appendingPathComponent("trimmed_output.caf")
				
				try writeToAACWithAVAudioFile(buffer: trimmedBuffer, to: trimmedSourceURL!)

			} else {
				await MainActor.run {
					TapeRecorderState.shared.status = .busy
				}

				Logger().debug(
					"Sending encode configuration as \(String(describing: config))")

				await RMAudioConverter.convert(
					input: self.sourceURL!, output: config.outputURL!,
					format: config.outputFormat)

				await MainActor.run {
					TapeRecorderState.shared.status = .idle
				}
			}

		case .existingSample:
			print("nil")
		}
	}
	
	private func trimPCMBuffer(buffer: AVAudioPCMBuffer, forwardsEndTime: CMTime, reverseEndTime: CMTime) -> AVAudioPCMBuffer? {
		
		let sampleRate = buffer.format.sampleRate
		let startTimeSeconds = reverseEndTime.seconds
		let endTimeSeconds = forwardsEndTime.seconds
		
		// Validate range
		let bufferDuration = Double(buffer.frameLength) / sampleRate
		guard startTimeSeconds >= 0 && endTimeSeconds <= bufferDuration && startTimeSeconds < endTimeSeconds else {
			Logger().error("Invalid trim range: \(startTimeSeconds) to \(endTimeSeconds) seconds (buffer duration: \(bufferDuration))")
			return nil
		}
		
		let startFrame = AVAudioFramePosition(startTimeSeconds * sampleRate)
		let endFrame = AVAudioFramePosition(endTimeSeconds * sampleRate)
		let frameCount = AVAudioFrameCount(endFrame - startFrame)
		
		guard let trimmedBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frameCount) else {
			Logger().error("Failed to create trimmed buffer")
			return nil
		}
		
		// copy audio data - handle interleaved vs non-interleaved
		if buffer.format.isInterleaved {
			// Interleaved
			let sourcePtr = buffer.floatChannelData![0]
			let destPtr = trimmedBuffer.floatChannelData![0]
			let channelCount = Int(buffer.format.channelCount)
			
			for frame in 0..<Int(frameCount) {
				for channel in 0..<channelCount {
					let sourceIndex = (Int(startFrame) + frame) * channelCount + channel
					let destIndex = frame * channelCount + channel
					destPtr[destIndex] = sourcePtr[sourceIndex]
				}
			}
		} else {
			// Non-interleaved
			for channel in 0..<Int(buffer.format.channelCount) {
				let source = buffer.floatChannelData![channel] + Int(startFrame)
				let destination = trimmedBuffer.floatChannelData![channel]
				destination.update(from: source, count: Int(frameCount))
			}
		}
		
		trimmedBuffer.frameLength = frameCount
		return trimmedBuffer
	}
	
	private func writeToAACWithAVAudioFile(buffer: AVAudioPCMBuffer, to url: URL) throws {
		if FileManager.default.fileExists(atPath: url.path) {
			try FileManager.default.removeItem(at: url)
		}
		
		let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: buffer.format.sampleRate, channels: buffer.format.channelCount, interleaved: false)!
		
		guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else {
			throw NSError(domain: "ConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create converter"])
		}
		
		let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: buffer.frameLength)!
		
		var error: NSError?
		let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
			outStatus.pointee = .haveData
			return buffer
		}
		
		if status == .error {
			throw error ?? NSError(domain: "ConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Conversion failed"])
		}
		
		let outputFile = try AVAudioFile(forWriting: url, settings: outputFormat.settings)
		try outputFile.write(from: convertedBuffer)
	}

}
