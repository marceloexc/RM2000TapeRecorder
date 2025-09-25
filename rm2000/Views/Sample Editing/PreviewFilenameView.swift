import SwiftUI

struct PreviewFilenameView: View {
	@State var previewFilename: String = ""
	@State private var sortedTagsArray: [String] = []
	@Binding var title: String
	@Binding var tags: Set<String>
	let audioFormat = TapeRecorderState.shared.sampleRecordAudioFormat.asString
	
	var body: some View {
    
		Text(generatePreviewFilename())
      .font(.caption)
      .foregroundColor(.accentColor)
			.onChange(of: tags) { newTags in
				sortedTagsArray = newTags.sorted()
			}
			.onAppear {
				sortedTagsArray = tags.sorted()
			}
	}
	
	// TODO - hardcoded file extension string
	private func generatePreviewFilename() -> String {
		var taggedString = ""
		
		for tag in sortedTagsArray {
			taggedString.append("\(tag)-")
		}
		
		return "\(title)__\(taggedString).\(audioFormat)"
	}
}

#Preview {
	PreviewFilenameView(
		title: .constant("ExampleTitle"),
		tags: .constant(["tag1", "tag2", "tag3"])
	)
}

