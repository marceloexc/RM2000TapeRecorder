import Foundation

struct SampleEditConfiguration {
	var deleteAfterComplete: Bool = false // this is true for TemporaryActiveRecording recordings
	
	var desiredAudioFormat: AudioFormat = .wav
	
	var startingTrimPoint: TimeInterval? = nil
	
	var endingTrimPoint: TimeInterval? = nil
	
	var directoryDestination: SampleDirectory? = nil
	
	init() { }
	
}
