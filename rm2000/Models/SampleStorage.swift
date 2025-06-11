import Combine
import UniformTypeIdentifiers
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
      directory: appState.sampleDirectory ?? <#default value#>)
		self.ArchiveDirectory = SampleDirectory(
			directory: WorkingDirectory.applicationSupportPath())
	}
}

class SampleDirectory: ObservableObject, DirectoryWatcherDelegate {
	

	@Published var samplesInStorage: [Sample] = []
	// todo - refactor indexedTags to automatically be called
	// when [files] changes in size
	@Published var indexedTags: Set<String> = []
	var directory: URL
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
						samplesInStorage.append(SampleFile)
						indexedTags.formUnion(SampleFile.tags)
						processedFilePaths.insert(filePath)
					}
				}
			}
			Logger.appState.info("Added \(directoryContents.count) files to \(self.directory.description)")

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
				let audioFormat = TapeRecorderState.shared.sampleRecordAudioFormat
				let filename = sample.id.uuidString + "." + audioFormat.asString
				let tempFilePath = WorkingDirectory.applicationSupportPath().appendingPathComponent(filename)
				
				let encodingConfig = EncodingConfig(outputFormat: TapeRecorderState.shared.sampleRecordAudioFormat, outputURL: tempFilePath, forwardStartTime: configuration.forwardEndTime, backwardsEndTime: configuration.reverseEndTime)
				
				try await encoder.encode(with: encodingConfig)
				
				let finalFilename = metadata.finalFilename(fileExtension: audioFormat.asString)
				
				try fileManager.moveItem(
					at: tempFilePath,
					to: self.directory.appendingPathComponent(finalFilename)
				)
				
				indexedTags.formUnion(metadata.tags)
			}
		}
	}
	
	private func setupDirectoryWatching() {
		let watcher = DirectoryWatcher(url: directory)
		watcher.delegate = self
		watcher.start()
		self.watcher = watcher
		Logger().info("DirectoryWatcher initialized at \(self.directory.path)")
	}
	
	func directoryWatcher(_ watcher: DirectoryWatcher, changed: DirectoryChangeSet) {
		DispatchQueue.main.async {
			for url in changed.newFiles {
				Logger().debug("New file added in sample directory....: \(url)")
				let path = url.path
				if !self.processedFilePaths.contains(path),
					 let sample = Sample(fileURL: url) {
					self.samplesInStorage.append(sample)
					self.indexedTags.formUnion(sample.tags)
					self.processedFilePaths.insert(path)
					Logger().debug("\(url.lastPathComponent) fits sample criteria!")
				}
			}
			
			for url in changed.deletedFiles {
				let path = url.path
				if self.processedFilePaths.contains(path) {
					self.samplesInStorage.removeAll { $0.fileURL.path == path }
					self.processedFilePaths.remove(path)
					Logger().debug("File deleted: \(url.lastPathComponent)")
				}
			}
		}
	}
}
