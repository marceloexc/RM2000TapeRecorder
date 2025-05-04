import SwiftUI
import Combine
import CoreMedia

struct EditSampleView<Model: FileRepresentable>: View {
	@StateObject private var viewModel: EditSampleViewModel<Model>
	
	init(recording: Model, onComplete: @escaping (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void) {
		_viewModel = StateObject(wrappedValue: EditSampleViewModel(recording: recording, onComplete: onComplete))
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 12) {
				Text("Rename Recording")
					.font(.headline)
				TrimmingPlayerView(
					recording: viewModel.model,
					forwardEndTime: $viewModel.forwardEndTime,
					reverseEndTime: $viewModel.reverseEndTime)
				
				VStack(alignment: .leading, spacing: 4) {
					Text("Title")
						.font(.caption)
						.foregroundColor(.secondary)
					TextField("New Filename", text: $viewModel.title)
						.textFieldStyle(RoundedBorderTextFieldStyle())
				}
				
				VStack(alignment: .leading, spacing: 4) {
					Text("Tags (comma-separated)")
						.font(.caption)
						.foregroundColor(.secondary)
					TokenInputField(tags: $viewModel.tags)
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
					PreviewFilenameView<Model>(viewModel: viewModel)
				}
				.padding(.top, 8)
				
				Button("Save Sample") {
					viewModel.saveSample()
				}
				.buttonStyle(.borderedProminent)
				.padding(.top, 8)
			}
			.padding()
			.frame(minWidth: 350, maxWidth: 400, minHeight: 300)
		}
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

@MainActor
class EditSampleViewModel<Model: FileRepresentable>: ObservableObject {
	@State var title: String = ""
	@State var tags: Set<String> = []
	@State var description: String = ""
	@State var forwardEndTime: CMTime? = nil
	@State var reverseEndTime: CMTime? = nil
	
	let model: Model
	private let onComplete: (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void
	var sortedTagsArray: [String] {
		return tags.sorted()
	}
	
	init(recording: Model, onComplete: @escaping (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void) {
		self.onComplete = onComplete
		self.model = recording
	}
	
	func saveSample() {
		var configuration = SampleEditConfiguration()
		
		configuration.directoryDestination = SampleStorage.shared.UserDirectory
		
		var metadata = SampleMetadata()
		metadata.title = title
		metadata.tags = tags
		metadata.description = description.isEmpty ? nil: description
		let createdSample = Sample(fileURL: model.fileURL, metadata: metadata)
		// force unwrap, since we just created it
		onComplete(createdSample, metadata, configuration)
	}
	
	// TODO - hardcoded file extension string

	func generatePreviewFilename() -> String {
		var taggedString = ""
		
		for tag in sortedTagsArray {
			taggedString.append("\(tag)-")
		}
		
		return "\(title)__\(taggedString).aac"
	}
	
}

#Preview {
	let testFile = URL(fileURLWithPath: "/Users/marceloexc/Developer/replica/rm2000Tests/Example--sample.aac")
	let recording = TemporaryActiveRecording(fileURL: testFile)
	return EditSampleView(recording: recording) { _, _, _ in
		// Empty completion handler
	}
}
