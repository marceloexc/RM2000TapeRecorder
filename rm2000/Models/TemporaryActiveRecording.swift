import Foundation
import OSLog

struct TemporaryActiveRecording {
	var id: UUID
	var fileURL: URL
	
	// TODO - hardcoded file extension string
  init(directory: URL) {
		
		// ensure directory exists
		// TODO - terrible - maybe belongs in SampleStorage instead?
    if !(directory.isDirectory) {
			
			try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
			Logger().info("Had to make a directory for the application support path at: \(directory)")
		}
		self.id = UUID()
    self.fileURL = directory.appendingPathComponent(".cached-\(id.uuidString).caf")
	}
	
	init(fileURL: URL) {
		self.fileURL = fileURL
		self.id = UUID()
	}
}
