import Foundation
import CoreMedia

struct SampleEditConfiguration {
	var deleteAfterComplete: Bool = false // this is true for TemporaryActiveRecording recordings
	
	var desiredAudioFormat: AudioFormat = .wav
	
	var forwardEndTime: CMTime? = nil
	
	var reverseEndTime: CMTime? = nil
	
	var directoryDestination: SampleDirectory? = nil
	
	init() { }
	
}
