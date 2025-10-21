import Combine
import CoreMedia
import SwiftUI
import SwiftUIIntrospect
import OSLog

struct EditSampleView<Model: FileRepresentable>: View {

  let model: Model
  @State private var title: String
  @State private var tags: Set<String>
  @State private var description: String?
  @State private var forwardEndTime: CMTime? = nil
  @State private var reverseEndTime: CMTime? = nil
  @State private var sampleExists: Bool = false
  @State private var didErrorForOverride: Bool = false
  @State private var didErrorForCancel: Bool = false
  @State private var isModified: Bool = false
  @Environment(\.dismiss) private var dismiss
  @FocusState private var focusedField: Bool
  
  // needed for having access to the Editing Panel
  // to close it
  weak var editingPanel: NSPanel?

  private let onComplete:
    (FileRepresentable, SampleMetadata, SampleEditConfiguration?) -> Void

  init(
    recording: Model,
    onComplete: @escaping (
      FileRepresentable, SampleMetadata, SampleEditConfiguration?
    ) -> Void
  ) {
    self.onComplete = onComplete
    self.model = recording
    
    if let sample = self.model as? Sample {
      _title = State(initialValue: sample.metadata.title)
      _tags = State(initialValue: Set(sample.metadata.tags))
      _description = State(initialValue: sample.metadata.description)
    } else {
      _title = State(initialValue: "")
      _tags = State(initialValue: Set<String>())
      _description = State(initialValue: "")
    }
  }

  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          Text("Edit Sample")
            .font(.headline)
          Spacer()
          
          TrimmingPlayerView(
            recording: model,
            forwardEndTime: $forwardEndTime,
            reverseEndTime: $reverseEndTime)
          .onChange(of: forwardEndTime) { isModified = true }
          .onChange(of: reverseEndTime) { isModified = true }
          .cornerRadius(8)
          
          Spacer()
          
          VStack(alignment: .leading, spacing: 4) {
            
            Text("Title")
              .font(.caption)
              .foregroundColor(.secondary)
            
            TextField("New Filename", text: $title)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .autocorrectionDisabled()
              .focused($focusedField)
              .onAppear {
                focusedField = true
              }
              .onChange(of: title) {
                isModified = true
              }
          }
          
          Spacer()
          
          VStack(alignment: .leading, spacing: 4) {
            Text("Tags (comma-separated)")
              .font(.caption)
              .foregroundColor(.secondary)
            TokenInputField(tags: $tags)
            
              .onChange(of: tags) { newValue in
                isModified = true
                
                let forbiddenChars = CharacterSet(
                  charactersIn: "_-/:*?\"<>|,;[]{}'&\t\n\r")
                tags = Set(
                  newValue.map { tag in
                    String(
                      tag.unicodeScalars.filter { !forbiddenChars.contains($0) })
                  })
                
                
                sampleExists = doesSampleAlreadyExist()
              }
            
          }
          
          DisclosureGroup("Additional Fields") {
            Text("Testing!")
          }
          .font(.caption)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        Divider()
        
        VStack(alignment: .trailing) {
          HStack {
            Text("Preview Filename")
              .font(.caption)
              .foregroundColor(.secondary)
            PreviewFilenameView(title: $title, tags: $tags)
            Spacer()
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 1)
        
        Divider()
      }
      EditSampleFooter(model: model, sampleExists: sampleExists, isModified: isModified, onDiscard: handleDiscard, onArchive: handleArchive, onApply: handleApply)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
    .frame(minHeight: 200)
    .alert("Replace existing sample?", isPresented: $didErrorForOverride) {
      Button("Replace", role: .destructive) {
        gatherAndComplete()
      }
      Button("Cancel", role: .cancel) {
      }
    } message: {
      Text("Another sample with identical title and tags already exists.")
    }
    .alert("Cancel Editing?", isPresented: $didErrorForCancel) {
      Button("Go Back", role: .cancel) {}
      Button("Confirm") {
        dismiss()
        editingPanel?.close()
      }
    } message: {
      Text("This recording will be lost once the app is quit.")
    }
  }
  
  private func handleDiscard() {
    if (model is TemporaryActiveRecording || isModified) {
      didErrorForCancel = true
    } else {
      editingPanel?.close()
    }
  }

  private func handleArchive() {
    // Add archive logic later
  }

  private func handleApply() {
    if title.isEmpty && tags.isEmpty {
      NSSound.beep()
    } else if sampleExists {
      didErrorForOverride = true
    } else {
      gatherAndComplete()
      editingPanel?.close()
    }
  }
  
  private func gatherAndComplete() {
    /// send all information to the SampleProcessor to get encoded.
    
    var metadata = SampleMetadata()
    metadata.outputDestination = SampleStorage.shared.UserDirectory
    metadata.title = title
    metadata.tags = tags
    
    let createdSample = Sample(fileURL: model.fileURL, metadata: metadata)
    
    /// if we did change the trim points, then we need a sample edit config
    if let forwardEndTime = forwardEndTime, let reverseEndTime = reverseEndTime {
      Logger.encoder.info("Trim detected")
      
      var configuration = SampleEditConfiguration()
      configuration.forwardEndTime = forwardEndTime
      configuration.reverseEndTime = reverseEndTime
      onComplete(createdSample, metadata, configuration)

    } else {
      onComplete(createdSample, metadata, nil)

    }
    
  }

  @MainActor private func doesSampleAlreadyExist() -> Bool {
    for sample in SampleStorage.shared.UserDirectory.samplesInStorage {
      if sample.metadata.title == title && sample.metadata.tags == tags {
        return true
      }
    }
    return false
  }
}

struct TokenInputField: View {
  @Binding var tags: Set<String>
  let suggestions = SampleStorage.shared.UserDirectory.indexedTags

  var body: some View {
    TokenField(.init(get: { Array(tags) }, set: { tags = Set($0) }))  // converting set<string> to [string]...stupid...
      .completions([String](suggestions))
  }
}

struct EditSampleFooter: View {
  let model: FileRepresentable
  let sampleExists: Bool
  let isModified: Bool
  let onDiscard: () -> Void
  let onArchive: () -> Void
  let onApply: () -> Void

  var body: some View {
    HStack {
      Button("Discard", role: .destructive, action: onDiscard)
        .keyboardShortcut(.cancelAction)
        .foregroundColor(.red)

      Spacer()
      if sampleExists {
        Label(
          "Sample with same title and tags already exists",
          systemImage: "exclamationmark.triangle"
        )
        .foregroundColor(.red)
        .font(.caption)
        .contentTransition(.opacity)
      }

      Button("Archive", action: onArchive)
        .buttonStyle(.bordered)

      Button("Apply Edits and Save", action: onApply)
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
    }
  }
}

#Preview {
  let testFile = URL(
    fileURLWithPath:
      "/Users/marceloexc/Developer/replica/rm2000Tests/Example--sample.aac")
  let recording = TemporaryActiveRecording(fileURL: testFile)
  return EditSampleView(recording: recording) { _, _, _ in
    // Empty completion handler
  }
}
