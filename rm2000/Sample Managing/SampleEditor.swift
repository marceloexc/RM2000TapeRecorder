import AVFoundation
import CSFBAudioEngine
import CoreMedia
import Foundation
import OSLog
import SFBAudioEngine

class SampleEditor {
  private var sourceBuffer: AVAudioPCMBuffer?
  let sample: FileRepresentable
  
  let metadata: SampleMetadata
  
  let editConfiguration: SampleEditConfiguration?
  
  init(sample: FileRepresentable, metadata: SampleMetadata, editConfiguration: SampleEditConfiguration) {
    self.sample = sample
    self.metadata = metadata
    self.editConfiguration = editConfiguration
  }
  
  init(sample: FileRepresentable, metadata: SampleMetadata) {
    self.sample = sample
    self.metadata = metadata
    self.editConfiguration = nil
  }
  
  func processAndConvert() async throws {
    
    // let glyphs update
    await MainActor.run { TapeRecorderState.shared.status = .busy }
    
    // TODO: - Don't use (String(describing: ))
    // when I log this, it gives some very unhelpful stats about what we encode
    // like `outputDestination: Optional(RM2000_Tape_Recorder.SampleDirectory)`
    Logger.encoder.info("""
      Encoder called: \(String(describing: self.sample))
      \(String(describing: self.metadata))
      \(String(describing: self.editConfiguration))
      """)
    
    /// get decodings
    guard let decoder = try? AudioDecoder(url: self.sample.fileURL) else {
      Logger.encoder.error("Failed to init decoder for \(self.sample.fileURL)")
      return
    }
    
    try decoder.open()
    let processingFormat = decoder.processingFormat
    
    Logger.encoder.info("Processing format: \(processingFormat), processing format length: \(decoder.length)")
    
    
    let frameCount = AVAudioFrameCount(decoder.length)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: frameCount)
    else {
      Logger.encoder.error("Failed to get buffers from the decoder for \(self.sample.fileURL)")
      return
    }
    
    try decoder.decode(into: buffer, length: frameCount)
    
    guard let trimmedBuffer = trimPCMBuffer(
      buffer: buffer,
      forwardsEndTime: (self.editConfiguration?.forwardEndTime!)!,
      reverseEndTime: (self.editConfiguration?.reverseEndTime!)!
    )
    else {
      Logger.encoder.error("Failed to trim buffer")
      return
    }
    
    let temporaryTrimmedFile = try createTemporaryFile()
    
    let outputFile = (metadata.outputDestination?.directory.appendingPathComponent(metadata.finalFinalname))!
    
    try writeToAACWithAVAudioFile(buffer: trimmedBuffer, to: temporaryTrimmedFile)
    
    await convert(
      from: temporaryTrimmedFile, to: outputFile,
      // TODO: - This piece of shit is so ugly
      format: AudioFormat(rawValue: (self.editConfiguration?.audioFormat)!.rawValue) ?? .mp3)
    
    
    // delete the original file
//    try? FileManager.default.removeItem(at: self.sourceURL!)
    
    await MainActor.run {
    TapeRecorderState.shared.status = .idle
    }
  }
  
  func convertDirectly() async {
    await convert(from: self.sample.fileURL, to: self.metadata.destinedOutput, format: self.metadata.fileFormat)
  }

  func convert(from fileURL: URL, to output: URL, format: AudioFormat) async {
    do {
      try AudioConverter.convert(fileURL, to: output)
    } catch {
      Logger.encoder.error("Conversion failed: \(error.localizedDescription)")
    }
  }
  
  func convert(from pcm: any PCMDecoding, to output: URL, format: AudioFormat) {
    
  }
  
  // MARK: - Private stuff
  
  private func createTemporaryFile() throws -> URL {
    let destination = self.metadata.outputDestination
    
    let temporaryDirectoryURL =
    try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: destination?.directory, create: true)
    
    let temporaryFilename = UUID().uuidString + "trimmed.caf"
    
    let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
    
    return temporaryFileURL
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
      Logger.encoder.error("Start time is less than zero for buffer")
      return nil
    }

    if endTimeSeconds > bufferDuration {
      Logger.encoder.info("End time larger than buffer duration - adjusting...")
      endTimeSeconds = bufferDuration
    }

    guard startTimeSeconds < endTimeSeconds else {
      Logger.encoder.error(
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
      Logger.encoder.error("Failed to create trimmed buffer")
      return nil
    }

    // copy audio data - handle interleaved vs non-interleaved
    if buffer.format.isInterleaved {

      Logger.encoder.info("Format is interleaved - converting...")
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
      Logger.encoder.info("Format is not-interleaved - converting...")

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
