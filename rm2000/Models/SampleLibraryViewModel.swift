import Foundation
import CoreTransferable
import Combine


struct SampleTagToken: Identifiable {
  var id: UUID
  var tag: String
}


@MainActor
class SampleLibraryViewModel: ObservableObject {
	@Published var listOfAllSamples: [Sample] = []
	@Published var indexedTags: [String] = []
	@Published var finishedProcessing: Bool = false
  @Published var sidebarSelection: SidebarSelection?
	@Published var detailSelection: SampleListItemModel.ID?
	@Published var showInspector: Bool = false
	@Published var slAudioPlayer = SLAudioPlayer()
	
	private var sampleStorage: SampleStorage
	private var cancellables = Set<AnyCancellable>()
	
	var selectedSample: Sample? {
		return matchToSample(id: detailSelection)
	}
	
	init(sampleStorage: SampleStorage = SampleStorage.shared) {
		self.sampleStorage = sampleStorage
		
		sampleStorage.UserDirectory.$samplesInStorage
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newFiles in
				self?.listOfAllSamples = newFiles
				self?.finishedProcessing = true
			}
			.store(in: &cancellables)
		
		sampleStorage.UserDirectory.$indexedTags
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newTags in
				self?.indexedTags = Array(newTags).sorted()
			}
			.store(in: &cancellables)
		
		// Watch for changes in selection and update audio player
		$detailSelection
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newSelection in
				guard let self = self else { return }
				if let sample = self.matchToSample(id: newSelection) {
					self.slAudioPlayer.loadAudio(from: sample.fileURL)
					if (self.slAudioPlayer.isAutoplay) {
						self.slAudioPlayer.play()
					}
				}
			}
			.store(in: &cancellables)
		
		// update music player slider as song plays
		slAudioPlayer.objectWillChange
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				self?.objectWillChange.send()
			}
			.store(in: &cancellables)
		
	}

	private func matchToSample(id: UUID?) -> Sample? {
		// match uuid from detailSelection to its according sample object
		guard let id = id else { return nil }
		return listOfAllSamples.first { $0.id == id }
	}
}

struct SampleListItemModel: Identifiable, Hashable {
	var id: UUID
	var text: String
	var file: FileRepresentable
	
	init(file: FileRepresentable) {
		if let sample = file as? Sample {
			self.id = sample.id 
			self.text = sample.title
		} else {
			self.id = UUID()
			self.text = file.fileURL.lastPathComponent
		}
		self.file = file
	}
	
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: SampleListItemModel, rhs: SampleListItemModel) -> Bool {
		return lhs.id == rhs.id
	}
}

// necessary extension for draggable objects in sample library window
extension SampleListItemModel: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .audio) { fileRepresentable in
      // when dragging from app to finder
      SentTransferredFile(fileRepresentable.file.fileURL)
    }
    // without this, finder wont recognize our dropped item
    ProxyRepresentation { fileRepresentable in fileRepresentable.file.fileURL}
  }
}
