import AVFoundation
import CSFBAudioEngine
import CoreMedia
import Foundation
import OSLog
import SFBAudioEngine

struct RMAudioConverter {
  static func convert(input: URL, output: URL, format: AudioFormat) async {
    do {
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

// TODO
// TODO
// TODO

// We are going to have to start refactoring this.
// The encoder should be able to catch errors and NOT automatically delete files if the encoder doesnt succeed.
// We should also be able to have an NSAlert with the error message just in case.

// once we implement sample collections, detect when leftover .cache caf files are in there and move them to archive

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

    // let glyphs update
    await MainActor.run {
      TapeRecorderState.shared.status = .busy
    }

    if config.forwardsEndTime != nil || config.reverseEndTime != nil {
      needsTrimming = true
    }

    isProcessing = true

    /*
		 TODO - this will need refactoring once we allow users to save their
		 quick recordings and convert them to normal samples
		 */
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
        print(
          "Processing format: \(processingFormat), processing format length: \(decoder.length)"
        )
        let frameCount = AVAudioFrameCount(decoder.length)
        guard
          let buffer = AVAudioPCMBuffer(
            pcmFormat: processingFormat, frameCapacity: frameCount)
        else {
          Logger().error(
            "Failed to get buffers from the decoder for \(self.sourceURL!)")
          return
        }

        try decoder.decode(into: buffer, length: frameCount)

        guard
          let trimmedBuffer = trimPCMBuffer(
            buffer: buffer,
            forwardsEndTime: config.forwardsEndTime!,
            reverseEndTime: config.reverseEndTime!
          )
        else {
          Logger().error("Failed to trim buffer")
          return
        }

        let baseName = sourceURL?.deletingPathExtension().lastPathComponent
        let newFileName = "\(baseName!)_t.caf"
        let trimmedSourceURL = sourceURL?.deletingLastPathComponent()
          .appendingPathComponent(newFileName)

        try writeToAACWithAVAudioFile(buffer: trimmedBuffer, to: trimmedSourceURL!)
        await RMAudioConverter.convert(
          input: trimmedSourceURL!, output: config.outputURL!,
          format: config.outputFormat)
        try? FileManager.default.removeItem(at: self.sourceURL!)
        try? FileManager.default.removeItem(at: trimmedSourceURL!)

      } else {
        Logger().debug(
          "Sending encode configuration as \(String(describing: config))")
        await RMAudioConverter.convert(
          input: self.sourceURL!, output: config.outputURL!,
          format: config.outputFormat)
        // remove trimmed output
        try? FileManager.default.removeItem(at: self.sourceURL!)
      }

    case .existingSample:
      fatalError("Not implemented yet")
    }

    await MainActor.run {
      TapeRecorderState.shared.status = .idle
    }
  }

  private func trimPCMBuffer(
    buffer: AVAudioPCMBuffer, forwardsEndTime: CMTime, reverseEndTime: CMTime
  ) -> AVAudioPCMBuffer? {

    let sampleRate = buffer.format.sampleRate
    let startTimeSeconds = reverseEndTime.seconds
    var endTimeSeconds = forwardsEndTime.seconds

    let bufferDuration = Double(buffer.frameLength) / sampleRate

    // validating range
    guard startTimeSeconds >= 0 else {
      Logger().error("Start time is less than zero for buffer")
      return nil
    }

    if endTimeSeconds > bufferDuration {
      Logger().info("End time larger than buffer duration - adjusting...")
      endTimeSeconds = bufferDuration
    }

    guard startTimeSeconds < endTimeSeconds else {
      Logger().error(
        "Invalid trim range: \(startTimeSeconds) to \(endTimeSeconds) seconds (buffer duration: \(bufferDuration))"
      )
      return nil
    }

    let startFrame = AVAudioFramePosition(startTimeSeconds * sampleRate)
    let endFrame = AVAudioFramePosition(endTimeSeconds * sampleRate)
    let frameCount = AVAudioFrameCount(endFrame - startFrame)

    guard
      let trimmedBuffer = AVAudioPCMBuffer(
        pcmFormat: buffer.format, frameCapacity: frameCount)
    else {
      Logger().error("Failed to create trimmed buffer")
      return nil
    }

    // copy audio data - handle interleaved vs non-interleaved
    if buffer.format.isInterleaved {

      Logger().info("Format is interleaved - converting...")
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
      Logger().info("Format is not-interleaved - converting...")

      for channel in 0..<Int(buffer.format.channelCount) {
        let source = buffer.floatChannelData![channel] + Int(startFrame)
        let destination = trimmedBuffer.floatChannelData![channel]
        destination.update(from: source, count: Int(frameCount))
      }
    }

    trimmedBuffer.frameLength = frameCount
    return trimmedBuffer
  }

  private func writeToAACWithAVAudioFile(buffer: AVAudioPCMBuffer, to url: URL)
    throws
  {
    if FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.removeItem(at: url)
    }

    let outputFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32, sampleRate: buffer.format.sampleRate,
      channels: buffer.format.channelCount, interleaved: false)!

    guard
      let converter = AVAudioConverter(from: buffer.format, to: outputFormat)
    else {
      throw NSError(
        domain: "ConversionError", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create converter"])
    }

    let convertedBuffer = AVAudioPCMBuffer(
      pcmFormat: outputFormat, frameCapacity: buffer.frameLength)!

    var error: NSError?
    let status = converter.convert(to: convertedBuffer, error: &error) {
      _, outStatus in
      outStatus.pointee = .haveData
      return buffer
    }

    if status == .error {
      throw error
        ?? NSError(
          domain: "ConversionError", code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Conversion failed"])
    }

    let outputFile = try AVAudioFile(
      forWriting: url, settings: outputFormat.settings)
    try outputFile.write(from: convertedBuffer)
  }

}
