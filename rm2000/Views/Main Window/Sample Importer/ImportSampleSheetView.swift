//
//  ImportSampleSheetView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 9/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportSampleSheetView: View {
  @Environment (\.dismiss) var dismiss
  @State private var isBeingDragged: Bool = false
  @State private var files: [URL] = []
  
  let onFilesSelected: ([URL]) -> Void
  
  weak var appDelegate: AppDelegate?

  init(onFilesSelected: @escaping ([URL]) -> Void) {
    self.onFilesSelected = onFilesSelected
  }
  
  var body: some View {
    if files.isEmpty {
      ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(.primary, style: StrokeStyle(lineWidth: 2, dash: [5]))
          .fill(Color(nsColor: .tertiarySystemFill))
        
        VStack {
          Text("Drop media files here")
          Text(files.first?.absoluteString ?? "No file selected")
        }
      }
      .frame(minHeight: 300)
      .padding()
      .onDrop(of: [.fileURL], delegate: ImportSampleDropDelegate(URLs: $files, onFilesSelected: onFilesSelected))
    } else {
      EditSampleView(recording: TemporaryActiveRecording(fileURL: files.first!)) {  FileRepresentable, SampleMetadata, SampleEditConfiguration in
        
        let processor = SampleProcessor(file: FileRepresentable, metadata: SampleMetadata, editConfig: SampleEditConfiguration)
        
        try? processor.apply()
        dismiss()
      }
    }
  }
}

struct ImportSampleDropDelegate: DropDelegate {
  @Binding var URLs: [URL]
  let onFilesSelected: ([URL]) -> Void
  
  func performDrop(info: DropInfo) -> Bool {
    guard info.hasItemsConforming(to: [.fileURL]) else { return false }
    
    let items = info.itemProviders(for: [.fileURL])
    
    var droppedURLs: [URL] = []
    let group = DispatchGroup()
    
    for item in items {
      group.enter()
      _ = item.loadObject(ofClass: URL.self) { url , _ in
        if let url = url {
          DispatchQueue.main.async {
            self.URLs.insert(url, at: 0)
            droppedURLs.append(url)
          }
        }
        group.leave()
      }
    }
    
    group.notify(queue: .main) {
      if !droppedURLs.isEmpty {
        self.onFilesSelected(droppedURLs)
      }
    }
    return true
  }
}

#Preview {
  ImportSampleSheetView { urls in
//    isShowingImportSheet = false
  }
}
