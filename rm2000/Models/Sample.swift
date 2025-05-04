import Foundation
import FZMetadata

struct Sample: Identifiable, Hashable {
	var id: UUID
	let fileURL: URL
	var filename: String?
	private var _metadata: SampleMetadata
	
	var metadata: SampleMetadata {
		get { return _metadata }
		set { _metadata = newValue }
	}
	
	var title: String {
		get { return metadata.title }
		set { metadata.title = newValue }
	}
	
	var tags: Set<String> {
		get { return metadata.tags }
		set { metadata.tags = newValue }
	}
	
	var description: String? {
		mutating get {
			metadata.loadDescription(from: fileURL)
			return metadata.description
		}
	}
	
	var fzMetadata: MetadataItem? {
		fileURL.metadata
	}
	
	// Initialize from an existing recording
	init(from newRecording: TemporaryActiveRecording) {
		self.id = newRecording.id
		self.fileURL = newRecording.fileURL
		self.filename = fileURL.lastPathComponent
		self._metadata = SampleMetadata()
	}
	
	init?(fileURL: URL) {
		// only urls that pass the regex text will be allowed
		guard Sample.passesRegex(fileURL.lastPathComponent) else {
			return nil
		}
		
		self.id = UUID()
		self.fileURL = fileURL
		self.filename = fileURL.lastPathComponent
		self._metadata = SampleMetadata(fileURL: fileURL)
	}
	
	init(fileURL: URL, metadata: SampleMetadata) {
		self.fileURL = fileURL
		self._metadata = metadata
		self.id = UUID()
	}
	
	private static func passesRegex(_ pathName: String) -> Bool {
		(try? regString.wholeMatch(in: pathName)) != nil
	}
	
	func finalFilename() -> String {
		return metadata.finalFilename()
	}
	
	// MARK: - Hashable Conformance, to be fair don't uderstand yet what it does
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: Sample, rhs: Sample) -> Bool {
		return lhs.id == rhs.id
	}
}
