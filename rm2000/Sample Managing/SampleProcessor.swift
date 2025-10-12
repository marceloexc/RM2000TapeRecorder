//
//  SampleProcessor.swift
//  rm2000
//
//  Created by Marcelo Mendez on 10/5/25.
//


class SampleProcessor {
  
  let file: FileRepresentable
  let metadata: SampleMetadata
  let editConfig: SampleEditConfiguration?
  
  // handle making filename and tempfilepath in here
  
  init(file: FileRepresentable, metadata: SampleMetadata) {
    self.file = file
    self.metadata = metadata
    self.editConfig = nil
  }
  
  init(file: FileRepresentable, metadata: SampleMetadata, editConfig: SampleEditConfiguration?) {
    self.file = file
    self.metadata = metadata
    self.editConfig = editConfig
  }
  
//  make sure it can `try?`
    
  func apply() throws {
    
    // what should it throw?
    // if edit config is not nil, then we want to use the encoder
    Task {
      do { await MainActor.run { TapeRecorderState.shared.status = .busy }}
      
      if let editConfig = editConfig {
        print("This wants to be edited")
        
        let encoder = SampleEditor(sample: self.file, metadata: self.metadata, editConfiguration: editConfig)
        do {
          try await encoder.processAndConvert()
        }
      }
      else {
        print("This doesn't need to be edited.")
        
        let encoder = SampleEditor(sample: self.file, metadata: self.metadata)
        
        Task { do { await encoder.convertDirectly() }}
      }
      
      do { await MainActor.run { TapeRecorderState.shared.status = .idle }}
    }
  }
}
