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
      Logger.encoder.info("Conversion complete")
    } catch {
    }
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

