import Foundation
import CoreMedia

struct SampleEditConfiguration {
	var deleteAfterComplete: Bool = false // this is true for TemporaryActiveRecording recordings
	
  var audioFormat: AudioFormat = TapeRecorderState.shared.sampleRecordAudioFormat
	
	var forwardEndTime: CMTime? = nil
	
	var reverseEndTime: CMTime? = nil
  
	init() { }
	
}
