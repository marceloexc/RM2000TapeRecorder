import Foundation

let regString = /(.+)--(.+)\.(.+)/

struct SampleMetadata {
	var title: String = ""
	var tags: Set<String> = []
	var description: String? = ""
	var fileFormat: AudioFormat = .wav
	var group: URL?
	
	init() {
		
	}
	
	init(fileURL: URL) {
		if let match = try? regString.firstMatch(in: fileURL.lastPathComponent) {
			// if passes regex, assume it is tagged
			self.title = String(match.1)
			self.tags = Set(String(match.2).components(separatedBy: "_"))
		} else {
			// else, just use the filename as the title
			self.title = fileURL.deletingPathExtension().lastPathComponent
		}
	}
	
	var tagsAsString: String {
		get { tags.sorted().joined(separator: ",")	 }
		set {
			tags = Set(newValue
				.components(separatedBy: ",")
				.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
				.filter { !$0.isEmpty })
		}
	}
	
	func finalFilename(fileExtension: String) -> String {
		// Construct the filename in the format "title--tag1_tag2_tag3.aac"
		if tags.isEmpty {
			// tags are empty, use omit them
			return "\(title).\(fileExtension)"
		} else {
			let formattedTags = tags.joined(separator: "_")
			return "\(title)--\(formattedTags).\(fileExtension)"
		}
	}
}
