import Foundation

let regString = /(.+)--(.+)\.(.+)/

struct SampleMetadata {
	var title: String = ""
	var tags: [String] = []
	var description: String? = ""
	var fileFormat: AudioFormat = .wav
	var group: URL?
	
	init() {
		
	}
	
	init(fileURL: URL) {
		if let match = try? regString.firstMatch(in: fileURL.lastPathComponent) {
			self.title = String(match.1)
			self.tags = String(match.2).components(separatedBy: "_")
		}
	}
	
	mutating func loadDescription(from fileURL: URL) {
		if description == nil {
			description = SampleMetadata.getDescription(fileURL: fileURL)
		}
	}
	
	private static func getDescription(fileURL: URL) -> String? {
		fileURL.metadata?.description
	}
	
	private static func getDuration(fileURL: URL) -> Double {
		if let metadata = fileURL.metadata {
			print(metadata.duration!)
			return metadata.duration?.rawValue ?? 0
		}
		return 0
	}
	
	func finalFilename(fileExtension: String = "mp3") -> String {
		// Construct the filename in the format "title--tag1_tag2_tag3.aac"
		let formattedTags = tags.joined(separator: "_")
		return "\(title)--\(formattedTags).\(fileExtension)"
	}
}
