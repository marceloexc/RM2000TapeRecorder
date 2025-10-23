import Foundation

class SampleProcessor {
  
  let file: FileRepresentable
  let metadata: SampleMetadata
  let editConfig: SampleEditConfiguration?
  
  // handle making filename and tempfilepath in here
  init(file: FileRepresentable, metadata: SampleMetadata, editConfig: SampleEditConfiguration? = nil) {
    self.file = file
    self.metadata = metadata
    self.editConfig = editConfig
  }
    
  func apply() async throws {
    await MainActor.run { TapeRecorderState.shared.status = .busy }
    defer { Task { await MainActor.run { TapeRecorderState.shared.status = .idle } } }
    
    let outputFile = metadata.outputDestination!.directory.appendingPathComponent(metadata.finalFinalname)
    let stagedFile: URL
    
    let editor = editConfig != nil
    ? SampleEditor(sample: file, metadata: metadata, editConfiguration: editConfig!)
    : SampleEditor(sample: file, metadata: metadata)
    
    stagedFile = try await (editConfig != nil
                            ? editor.processAndConvert()
                            : editor.convertDirectly()) ?? { throw SampleEditorError.failure }()
    
    try FileManager.default.moveItem(at: stagedFile, to: outputFile)
  }
}
