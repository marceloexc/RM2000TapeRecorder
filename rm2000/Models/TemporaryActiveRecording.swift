import Foundation
import OSLog

struct TemporaryActiveRecording {
	var id: UUID
	var fileURL: URL
	
	// TODO - hardcoded file extension string
	init() {
		
		// ensure directory exists
		// TODO - terrible - maybe belongs in SampleStorage instead?
		// (why are we still using workingdirectory? that thing needs to die...
		if !(WorkingDirectory.applicationSupportPath().isDirectory) {
			
			let directory = WorkingDirectory.applicationSupportPath()
			
			try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
			Logger().info("Had to make a directory for the application support path at: \(directory)")
		}
		self.id = UUID()
		self.fileURL = WorkingDirectory.applicationSupportPath()
			.appendingPathComponent("\(id.uuidString).aac")
	}
	
	init(fileURL: URL) {
		self.fileURL = fileURL
		self.id = UUID()
	}
}
