import Combine
import UniformTypeIdentifiers
import FZMetadata
import Foundation
import OSLog
import SwiftUICore
import SwiftDirectoryWatcher

@MainActor
final class SampleStorage: ObservableObject {

	let appState = AppState.shared
	static let shared = SampleStorage()

	@Published var UserDirectory: SampleDirectory
	@Published var ArchiveDirectory: SampleDirectory

	init() {
		self.UserDirectory = SampleDirectory(
			directory: appState.sampleDirectory ?? WorkingDirectory.applicationSupportPath())
		self.ArchiveDirectory = SampleDirectory(
			directory: WorkingDirectory.applicationSupportPath())
	}
}

class SampleDirectory: ObservableObject, DirectoryWatcherDelegate {
	

	@Published var files: [Sample] = []
	// todo - refactor indexedTags to automatically be called
	// when [files] changes in size
	@Published var indexedTags: Set<String> = []
	var directory: URL
	private var query = MetadataQuery()
	private var processedFilePaths: Set<String> = []
	
	private var watcher: DirectoryWatcher?
	
	let fileManager = FileManager.default
	

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
				// Only add files we haven't processed yet
				let filePath = fileURL.path
				if !processedFilePaths.contains(filePath) {
					if let SampleFile = Sample(fileURL: fileURL) {
						files.append(SampleFile)
						indexedTags.formUnion(SampleFile.tags)
						processedFilePaths.insert(filePath)
					}
				}
			}
			Logger.appState.info("Added \(directoryContents.count) files as FZMetadata to \(self.directory.description)")

		} catch {
			Logger().error("Error initial listing of directory contents: \(error.localizedDescription)")
		}
	}

	// having a lot of fun with arg labels today :)
	func applySampleEdits(to sample: FileRepresentable, for metadata: SampleMetadata, with configuration: SampleEditConfiguration) {

		var needsEncoding: Bool = false
		
		if (sample is TemporaryActiveRecording) {
			needsEncoding = true
		}
		
		Task {
			do {
				let encoder = Encoder(fileURL: sample.fileURL)
				
				let filename = sample.id.uuidString + ".mp3" // TODO - fix this
				let tempFilePath = WorkingDirectory.applicationSupportPath().appendingPathComponent(filename)
				let configuration = EncodingConfig(outputFormat: .mp3, outputURL: tempFilePath)
				
				try await encoder.encode(with: configuration)
				
				let finalFilename = metadata.finalFilename()
				
				try fileManager.moveItem(
					at: tempFilePath,
					to: self.directory.appendingPathComponent(finalFilename)
				)
				
				indexedTags.formUnion(metadata.tags)
			}
		}
		
//		do {
//			
//			// first encode with a temp name + .mp3
//			
//			// then get a ref to the file, move it
//			
//			// and then finally commit everything into a new Sample()
//			
	}

	// todo - this does not belong here!
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
		let watcher = DirectoryWatcher(url: directory)
		watcher.delegate = self
		watcher.start()
		self.watcher = watcher
		Logger().info("DirectoryWatcher initialized at \(directory.path)")
	}
	
	func directoryWatcher(_ watcher: DirectoryWatcher, changed: DirectoryChangeSet) {
		DispatchQueue.main.async {
			for url in changed.newFiles {
				Logger().debug("New file added in sample directory....: \(url)")
				let path = url.path
				if !self.processedFilePaths.contains(path),
					 let sample = Sample(fileURL: url) {
					self.files.append(sample)
					self.indexedTags.formUnion(sample.tags)
					self.processedFilePaths.insert(path)
					Logger().debug("\(url.lastPathComponent) fits sample criteria!")
				}
			}
			
			for url in changed.deletedFiles {
				let path = url.path
				if self.processedFilePaths.contains(path) {
					self.files.removeAll { $0.fileURL.path == path }
					self.processedFilePaths.remove(path)
					Logger().debug("File deleted: \(url.lastPathComponent)")
				}
			}
		}
	}
}
