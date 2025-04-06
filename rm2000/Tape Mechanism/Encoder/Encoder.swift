import SwiftLAME
import Foundation
import AVFoundation
import CoreMedia
import OSLog

struct AudioConverter {
	static func convert(input: URL, output: URL, format: AudioFormat) async {
		guard format == .mp3 else {
			Logger().error("Unsupported format: \(String(describing: format))")
			return
		}
		
		do {
			let progress = Progress()
			let encoder = try SwiftLameEncoder(
				sourceUrl: input,
				configuration: .init(
					sampleRate: .default,
					bitrateMode: .constant(320),
					quality: .best
				),
				destinationUrl: output,
				progress: progress
			)
			
			try await encoder.encode(priority: .userInitiated)
			Logger().info("Conversion complete")
		} catch {
			Logger().error("Conversion failed: \(error.localizedDescription)")
		}
	}
}


struct EncodingConfig {
	
	let outputFormat: AudioFormat
	let outputURL: URL?
	let forwardStartTime: CMTime?
	let backwardsEndTime: CMTime?
	
	init(
		outputFormat: AudioFormat,
		outputURL: URL? = nil,
		forwardStartTime: CMTime? = nil,
		backwardsEndTime: CMTime? = nil
	) {
		self.outputFormat = outputFormat
		self.outputURL = outputURL
		self.forwardStartTime = forwardStartTime
		self.backwardsEndTime = backwardsEndTime
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
		
		if let forwardStart = config.forwardStartTime, let backwardsEnd = config.backwardsEndTime {
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
				// i cant use formatconverter automatically - i have to convert to pcmbuffer, then render as a .caf, then formatconvert
				// function here
				
				let buffer = getPCMBuffer(fileURL: self.sourceURL!)
				let extractedBuffer = getExtractedBufferPortion(pcmBuffer: buffer!)
				let temporaryFileURL = saveTemporaryAudioFile(pcmBuffer: extractedBuffer)
				
				guard let tempURL = temporaryFileURL else {
					Logger().error("Temp file URL was nil.")
					return
				}
			
				await AudioConverter.convert(input: tempURL, output: config.outputURL!, format: config.outputFormat)

			} else {
				print("converting")
				await AudioConverter.convert(input: self.sourceURL!, output: config.outputURL!, format: .mp3)
			}
			
		case .existingSample:
			print("nil")
		}
	}
	
	private func getPCMBuffer(fileURL: URL) -> AVAudioPCMBuffer? {
		
		do {
			let audioFile = try! AVAudioFile(forReading: fileURL)
			
			let format = audioFile.processingFormat
			let frameCount = AVAudioFrameCount(audioFile.length)
			
			guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
				Logger().error("Failed to create AVAudioPCMBuffer for \(audioFile)")
				return nil
			}
			
			try audioFile.read(into: buffer)

			return buffer
		} catch {
			Logger().error("Error: \(error.localizedDescription)")
			return nil
		}
	}
	
	private func getExtractedBufferPortion(pcmBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
		return pcmBuffer
	}
	
	private func saveTemporaryAudioFile(pcmBuffer: AVAudioPCMBuffer) -> URL? {
		
		let temporaryFilename = UUID().uuidString + ".caf"
		
		do {
			let outputURL = WorkingDirectory.applicationSupportPath().appendingPathComponent(temporaryFilename)
			
			let outputFile = try AVAudioFile(forWriting: outputURL, settings: pcmBuffer.format.settings)
			try outputFile.write(from: pcmBuffer)
			
			Logger().info("Successfully wrote temporary audiofile as \(temporaryFilename)")
			
			return outputURL
		} catch {
			Logger().error("Error: \(error.localizedDescription)")
			return nil
		}
	}
	
	private func saveToFile() {
		
	}
}
