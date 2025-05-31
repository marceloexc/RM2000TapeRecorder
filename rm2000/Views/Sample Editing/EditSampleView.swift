import SwiftUI
import Combine
import CoreMedia

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
	@Environment(\.dismiss) private var dismiss
	@FocusState private var focusedField: Bool
	
	private let onComplete: (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void
	
	init(recording: Model, onComplete: @escaping (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void) {
		self.onComplete = onComplete
		_title = State(initialValue: "")
		_tags = State(initialValue: Set<String>())
		_description = State(initialValue: "")
		self.model = recording
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 12) {
				Text("Rename Recording")
					.font(.headline)
				TrimmingPlayerView(
					recording: model,
					forwardEndTime: $forwardEndTime,
					reverseEndTime: $reverseEndTime)
				
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
						.onChange(of: title) { formattedText in
							title = formattedText.replacingOccurrences(of: "-", with: " ")
							sampleExists = doesSampleAlreadyExist()
						}
				}
				
				VStack(alignment: .leading, spacing: 4) {
					Text("Tags (comma-separated)")
						.font(.caption)
						.foregroundColor(.secondary)
					TokenInputField(tags: $tags)
					
						.onChange(of: tags) { newValue in
							let forbiddenChars = CharacterSet(charactersIn: "_-/:*?\"<>|,;[]{}'&\t\n\r")
							tags = Set(newValue.map { tag in
								String(tag.unicodeScalars.filter { !forbiddenChars.contains($0) })
							})
							sampleExists = doesSampleAlreadyExist()
						}
					
				}
				DisclosureGroup("Additional Settings") {
					VStack(alignment: .leading, spacing: 4) {
						Text("Description (optional)")
							.font(.caption)
							.foregroundColor(.secondary)
						TextEditor(text: .constant("Placeholder"))
							.font(.system(size: 14, weight: .medium, design: .rounded)) // Uses a rounded, medium-weight system font
							.lineSpacing(10) // Sets the line spacing to 10 points
							.border(Color.gray, width: 1)
					}.padding(.top, 8)
				}
				VStack(alignment: .leading, spacing: 4) {
					Text("Preview:")
						.font(.caption)
						.foregroundColor(.secondary)
					PreviewFilenameView(title: $title, tags: $tags)
				}
				.padding(.top, 8)
				
				HStack {
					Button("Cancel", role: .cancel) {
						didErrorForCancel = true
					}.keyboardShortcut(.cancelAction)
					
					Spacer()
					
					if sampleExists {
						HStack {
							Label("Sample with same title and tags already exists", systemImage: "exclamationmark.triangle")
								.id(sampleExists)
								.foregroundColor(.red)
								.contentTransition(.opacity)
								.font(.caption)
						}
					}
					
					Button("Save Sample") {
						if (title.isEmpty && tags.isEmpty) {
							NSSound.beep()
						} else {
							if (sampleExists) {
								didErrorForOverride = true
							} else {
								gatherAndComplete()
							}
						}
					}
					.buttonStyle(.borderedProminent)
					.padding(.top, 8)
				}.keyboardShortcut(.defaultAction)
			}
			.padding()
		}
		.alert("Replace existing sample?", isPresented: $didErrorForOverride) {
			Button("Replace", role: .destructive) {
				gatherAndComplete()
			}
			Button("Cancel", role: .cancel) { }
		} message: {
			Text("Another sample with identical title and tags already exists.")
		}
		.alert("Cancel Editing?", isPresented: $didErrorForCancel) {
			Button("Go Back", role: .cancel) { }
			Button("Confirm") {
				dismiss()
			}
		} message: {
			Text("This recording will be lost once the app is quit.")
		}
	}
	
	private func gatherAndComplete() {
		var configuration = SampleEditConfiguration()
		configuration.directoryDestination = SampleStorage.shared.UserDirectory
		configuration.forwardEndTime = forwardEndTime
		configuration.reverseEndTime = reverseEndTime
		
		var metadata = SampleMetadata()
		metadata.title = title
		metadata.tags = tags
		var createdSample = Sample(fileURL: model.fileURL, metadata: metadata)
		onComplete(createdSample, metadata, configuration)
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
		TokenField(.init(get: { Array(tags) }, set: { tags = Set($0) })) // converting set<string> to [string]...stupid...
			.completions([String](suggestions))
	}
}

#Preview {
	let testFile = URL(fileURLWithPath: "/Users/marceloexc/Developer/replica/rm2000Tests/Example--sample.aac")
	let recording = TemporaryActiveRecording(fileURL: testFile)
	return EditSampleView(recording: recording) { _, _, _ in
		// Empty completion handler
	}
}
