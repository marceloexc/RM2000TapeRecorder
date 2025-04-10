import SwiftUI
import CoreMedia

struct EditSampleView<Model: FileRepresentable>: View {
	
	let model: Model
	@State private var title: String
	@State private var tags: String
	@State private var description: String?
	@State private var forwardEndTime: CMTime? = nil
	@State private var reverseEndTime: CMTime? = nil
	private let onComplete: (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void
	
	init(recording: Model, onComplete: @escaping (FileRepresentable, SampleMetadata, SampleEditConfiguration) -> Void) {
		self.onComplete = onComplete
		_title = State(initialValue: "")
		_tags = State(initialValue: "")
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
				}
				
				VStack(alignment: .leading, spacing: 4) {
					Text("Tags (comma-separated)")
						.font(.caption)
						.foregroundColor(.secondary)
					TextField("Enter Tags", text: $tags)
						.textFieldStyle(RoundedBorderTextFieldStyle())
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
						
						Text("Convert Format")
							.font(.caption)
							.foregroundColor(.secondary)
						Menu {
							Button {
								// do something
							} label: {
								Text("Linear")
								Image(systemName: "arrow.down.right.circle")
							}
							Button {
								// do something
							} label: {
								Text("Radial")
								Image(systemName: "arrow.up.and.down.circle")
							}
						} label: {
							Text("Style")
							Image(systemName: "tag.circle")
						}
						
					}.padding(.top, 8)
				}
				VStack(alignment: .leading, spacing: 4) {
					Text("Preview:")
						.font(.caption)
						.foregroundColor(.secondary)
					PreviewFilenameView(title: $title, tags: $tags)
				}
				.padding(.top, 8)
				
				Button("Save Sample") {
					
					var configuration = SampleEditConfiguration()
					
					configuration.directoryDestination = SampleStorage.shared.UserDirectory
					
					var metadata = SampleMetadata()
					metadata.title = title
					metadata.tagsAsString = tags
//					let staged = Sample(newRecording: model as! TemporaryActiveRecording, title: title, tags: tags, description: description)
					var createdSample = Sample(fileURL: model.fileURL, metadata: metadata)
					// force unwrap, since we just created it
					onComplete(createdSample, metadata, configuration)
				}
				.buttonStyle(.borderedProminent)
				.padding(.top, 8)
			}
			.padding()
			.frame(minWidth: 350, maxWidth: 400, minHeight: 300)
		}
	}
}

struct PreviewFilenameView: View {
	@State var previewFilename: String = ""
	@Binding var title: String
	@Binding var tags: String
	
	var body: some View {
		Text(generatePreviewFilename())
			.font(.system(size: 12, weight: .regular, design: .monospaced))
			.foregroundColor(Color(red: 1, green: 0.6, blue: 0)) // Warmer orange
			.shadow(color: .orange.opacity(0.4), radius: 1, x: 0, y: 0) // Glow effect
			.padding(4)
			.frame(maxWidth: .infinity)
			.background(Color.black)
	}
	
	// TODO - hardcoded file extension string
	private func generatePreviewFilename() -> String {
		return ("\(title)__\(tags).aac")
	}
}
