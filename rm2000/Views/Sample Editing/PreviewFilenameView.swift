import SwiftUI

struct PreviewFilenameView: View {
	@State var previewFilename: String = ""
	@State private var sortedTagsArray: [String] = []
	@Binding var title: String
	@Binding var tags: Set<String>
	let audioFormat = TapeRecorderState.shared.sampleRecordAudioFormat.asString
	
	var body: some View {
		Text(generatePreviewFilename())
			.font(.system(size: 12, weight: .regular, design: .monospaced))
			.foregroundColor(Color(red: 1, green: 0.6, blue: 0))
			.padding(4)
			.frame(maxWidth: .infinity)
			.background(Color.black)
			.contentTransition(.numericText())
			.animation(.easeInOut, value: title)
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

