import SwiftUI

struct InspectorView: View {
	@ObservedObject var viewModel: SampleLibraryViewModel
	
    var body: some View {
			
			if let sample = viewModel.selectedSample {
				Text(sample.fileURL.absoluteString)
			} else {
				Text("No Sample selected")
			}
        
    }
}

#Preview {
	InspectorView(viewModel: SampleLibraryViewModel())
}
