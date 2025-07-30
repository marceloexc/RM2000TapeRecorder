import SwiftUI

struct InspectorView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
      if let sample = viewModel.selectedSamples.first as! Sample? {
				Form {
					Section(header: Text("Metadata")) {
						HStack {
							Text("Title")
							Spacer()
							Text(sample.title)
								.foregroundColor(.secondary)
						}
						
						HStack {
							Text("Tags")
							Spacer()
							ForEach(Array(sample.tags), id: \.self) { tagName in
								TagComponent(string: tagName)
							}
						}
						
						//						if let desc = sample.description {
						//							VStack(alignment: .leading) {
						//								Text("Description")
						//								Text(desc)
						//									.foregroundColor(.secondary)
						//									.font(.body)
						//									.fixedSize(horizontal: false, vertical: true)
						//							}
						//						}
					}
					Section(header: Text("File Info")) {
						HStack {
							Text("Filename")
							Spacer()
							Text(sample.filename ?? "Unknown")
								.foregroundColor(.secondary)
						}
						
						HStack {
							Text("File path")
							Spacer()
							Text(sample.fileURL.path)
								.foregroundColor(.secondary)
								.truncationMode(.middle)
						}
						HStack {
							Text("File size")
							Spacer()
							let rawByteSize: Int64 = Int64(truncatingIfNeeded: sample.fileURL.fileSize ?? 0)
							let fileSizeWithUnit = ByteCountFormatter.string(fromByteCount: rawByteSize, countStyle: .file)
							Text(fileSizeWithUnit)
								.foregroundColor(.secondary)
								.truncationMode(.middle)
						}
						Button {
							NSWorkspace.shared.activateFileViewerSelecting([sample.fileURL])
						} label: {
							Image("SmallHappyFolder")
								.resizable()
								.scaledToFit()
								.frame(width: 16, height: 16)
							Text("Reveal in Finder")
						}

					}
				}
				.formStyle(.grouped)
			} else {
				Text("No Sample selected")
					.padding()
			}
		}
		.padding(-10)
	}
}

#Preview {
	InspectorView(viewModel: SampleLibraryViewModel())
}
