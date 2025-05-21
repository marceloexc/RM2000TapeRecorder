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
				
				let trimmedSourceURL = sourceURL?.deletingLastPathComponent().appendingPathComponent("copy.aac")
				
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
		let startFrame = AVAudioFramePosition(reverseEndTime.seconds * sampleRate)
		let endFrame = AVAudioFramePosition(forwardsEndTime.seconds * sampleRate)
		
		// Validate range
		if startFrame < 0 || endFrame > AVAudioFramePosition(buffer.frameLength) || startFrame >= endFrame {
			Logger().error("Invalid trim range: start=\(startFrame), end=\(endFrame), buffer length=\(buffer.frameLength)")
			return nil
		}
		
		let frameCount = AVAudioFrameCount(endFrame - startFrame)
		
		print("Trimming from \(startFrame) to \(endFrame) (\(frameCount) frames)")
		
		guard let trimmedBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frameCount) else {
			return nil
		}
		
		for channel in 0..<Int(buffer.format.channelCount) {
			let source = buffer.floatChannelData![channel] + Int(startFrame)
			let destination = trimmedBuffer.floatChannelData![channel]
			destination.update(from: source, count: Int(frameCount))
		}
		
		trimmedBuffer.frameLength = frameCount
		return trimmedBuffer
	}
	
	private func writeToAACWithAVAudioFile(buffer: AVAudioPCMBuffer, to url: URL) throws {
		let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: buffer.format.sampleRate, channels: buffer.format.channelCount, interleaved: false)!
		
		// Use m4a
		guard let outputFormat = AVAudioFormat(settings: [
			AVFormatIDKey: kAudioFormatMPEG4AAC,
			AVSampleRateKey: format.sampleRate,
			AVNumberOfChannelsKey: format.channelCount
		]) else {
			throw NSError(domain: "InvalidFormat", code: -1, userInfo: nil)
		}
		
		let outputFile = try AVAudioFile(forWriting: url, settings: outputFormat.settings)
		try outputFile.write(from: buffer)
	}

}
