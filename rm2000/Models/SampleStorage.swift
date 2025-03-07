import Combine
import UniformTypeIdentifiers
import FZMetadata
import Foundation
import OSLog
import SwiftUICore

@MainActor
final class SampleStorage: ObservableObject {

	let appState = AppState.shared
	static let shared = SampleStorage()

	@Published var UserDirectory: SampleDirectory
	@Published var ArchiveDirectory: SampleDirectory

	init() {
		self.UserDirectory = SampleDirectory(
			directory: appState.sampleDirectory!)
		self.ArchiveDirectory = SampleDirectory(
			directory: WorkingDirectory.applicationSupportPath())
	}
}

class SampleDirectory: ObservableObject {

	@Published var files: [Sample] = []
	// todo - refactor indexedTags to automatically be called
	// when [files] changes in size
	@Published var indexedTags: Set<String> = []
	var directory: URL
	private var query = MetadataQuery()

	init(directory: URL) {
		self.directory = directory
		startInitialFileScan()
		setupDirectoryWatching()
	}
	
	private func startInitialFileScan() {
		do {
			let directoryContents = try FileManager.default.contentsOfDirectory(
				at: self.directory, includingPropertiesForKeys: nil)

			for fileURL in directoryContents {
				if let SampleFile = Sample(fileURL: fileURL) {
					files.append(SampleFile)
					indexedTags.formUnion(SampleFile.tags)
				}
			}
			Logger.appState.info("Added \(directoryContents.count) files as FZMetadata to \(self.directory.description)")

		} catch {
			//			Logging.appState.error("Error initial listing of directory contents: \(error.localizedDescription)")
		}
	}

	func applySampleEdits(fromFile: URL, createdSample: Sample) {

		let fileManager = FileManager.default

		do {
			
			// TODO - hardcoded
			let uglyStringPleaseFixMePleasePlease = createdSample.finalFilename()
			
			try fileManager.moveItem(at: fromFile, to: self.directory.appendingPathComponent(uglyStringPleaseFixMePleasePlease))
			
			Logger().info("Applying sample edits and moving from \(fromFile) to \(self.directory.appendingPathComponent(uglyStringPleaseFixMePleasePlease))")

			// TODO - this is ugly
			if !((createdSample.description?.isEmpty) != nil) {
				setDescriptionFieldInFile(
					createdSample, (createdSample.description ?? ""))
			}
			
			indexedTags.formUnion(createdSample.tags)
		} catch {
			Logger.appState.error("Can't move file")
		}
	}

	private func setDescriptionFieldInFile(
		_ createdSample: Sample, _ description: String
	) {
		/*
			 why two file attributes that almost do the exact same thing?
			 because turns out that kMDItemFinderComment is unreliable,
			 (https://apple.stackexchange.com/questions/471023/to-copy-a-file-and-preserve-its-comment)
			 and this is a way of having redundancy.
			 */

		let attrs = [
			"com.apple.metadata:kMDItemComment",
			"com.apple.metadata:kMDItemFinderComment",
		]
		let fileURL = createdSample.fileURL

		if let descriptionData = description.data(using: .utf8) {
			do {
				try attrs.forEach { attr in
					try fileURL.setExtendedAttribute(
						data: descriptionData, forName: attr)
				}
			} catch {
				Logger.appState.error(
					"Couldn't apply xattr's to \(createdSample)")
			}
		}
	}
	
	private func setupDirectoryWatching() {
		query.searchLocations = [self.directory]
		
		/*
		 UTType doesnt have a specific type for aac audio so this is whats needed
		 
		 Stupid...
		 
		 or...maybe im stupid...maybe these shouldnt be .aac files at all, and should be .m4a
		 
		 https://en.wikipedia.org/wiki/Advanced_Audio_Coding
		 */
		query.predicate = { $0.contentType == [.mp3, .wav, UTType("public.aac-audio")] }
		
		query.monitorResults = true
		
		query.resultsHandler = { [weak self] items, difference in
			DispatchQueue.main.async {
				
				for new in difference.added {
					
					if let createdSample = Sample(fileURL: new.url!) {
						Logger.appState.info("New content detected: \(String(describing: new.url)) for \(self?.directory)")
						self?.files.append(createdSample)
						self?.indexedTags.formUnion(createdSample.tags)
						print(self?.indexedTags as Any)
					} else {
						Logger.appState.info("Newly added content rejected: \(String(describing: new.url))")
					}
				}
				for changed in difference.changed {
					if let movedSample = Sample(fileURL: changed.url!) {
						print("\(movedSample) has moved!")
					}
				}
				
				for removed in difference.removed {
					if let deletedSample = Sample(fileURL: removed.url!) {
						// Check if the file actually doesn't exist before removing it
						let fileManager = FileManager.default
						if !fileManager.fileExists(atPath: removed.url!.path) {
							Logger.appState.info("Deleting sample from library: \(String(describing: removed.url))")
							
							// Remove from files array
							if let index = self?.files.firstIndex(where: { $0.fileURL == deletedSample.fileURL }) {
								self?.files.remove(at: index)
							}
							Logger.appState.info("Content removed: \(String(describing: removed.url))")
						} else {
							Logger.appState.info("File reported as removed but still exists: \(String(describing: removed.url))")
						}
					}
				}
			}
		}
		query.start()
	}
}
