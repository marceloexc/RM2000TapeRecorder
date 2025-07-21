import SwiftUI

struct RecordingsTableView: View {
  @ObservedObject var viewModel: SampleLibraryViewModel
  let viewType: DetailViewType
  
  private var filteredSamples: [Sample] {
    switch viewType {
    case .all:
      return viewModel.filteredSamples
    case .tagged(let tagName):
      return viewModel.samples.filter { $0.tags.contains(tagName) }
    case .untagged:
      return viewModel.samples.filter { $0.tags.isEmpty }
    }
  }
  
  
    var body: some View {
      Table(filteredSamples) {
        TableColumn("Name", value: \.filename!)
        TableColumn("Title", value: \.title)
        TableColumn("Tags") { sample in
          Text("\(sample.tags)")
        }
      }
    }
}

#Preview {
//    RecordingsTableView()
}
