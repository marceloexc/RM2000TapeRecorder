import Combine
import CoreTransferable
import Foundation

struct SampleTagToken: Identifiable, Hashable {
  var id: UUID
  var tag: String
}

class SampleLibraryViewModel: ObservableObject {
  @Published var samples: [Sample] = []
  @Published var indexedTags: [String] = []
  @Published var finishedProcessing: Bool = false
  @Published var sidebarSelection: SidebarSelection?
  @Published var detailSelection: SampleListItemModel.ID?
  @Published var showInspector: Bool = false
  @Published var slAudioPlayer = SLAudioPlayer()
  @Published var currentTime: Double = 0
		@Published var searchText = ""
		@Published var currentSearchToken = [SampleTagToken]()
		@Published var allTokens: [SampleTagToken] = []

  private var sampleStorage: SampleStorage
  private var cancellables = Set<AnyCancellable>()

  var selectedSample: Sample? {
    return matchToSample(id: detailSelection)
  }
		
		var suggestedSearchTokens: [SampleTagToken] {
				if searchText.isEmpty {
						return Array(allTokens)
				} else {
						return allTokens.filter { $0.tag.hasPrefix(searchText) }
				}
		}
		
		var filteredSamples: [Sample] {
				guard !searchText.isEmpty || !currentSearchToken.isEmpty else { return samples }
				print(searchText)
				print(currentSearchToken)
				
				return samples.filter { sample in
						let matchesText = searchText.isEmpty || sample.title.lowercased().contains(searchText.lowercased())
						let tokenTags = Set(currentSearchToken.map { $0.tag })
						let sampleTags = Set(sample.tags)
						let matchesTokens = currentSearchToken.isEmpty || !sampleTags.isDisjoint(with: tokenTags)
						
						return matchesText && matchesTokens
				}
		}

  init(sampleStorage: SampleStorage = SampleStorage.shared) {
    self.sampleStorage = sampleStorage

    Task { @MainActor in
      sampleStorage.UserDirectory.$samplesInStorage
        .sink { [weak self] newFiles in
          self?.samples = newFiles
          self?.finishedProcessing = true
        }
        .store(in: &cancellables)

      sampleStorage.UserDirectory.$indexedTags
        .sink { [weak self] newTags in
          self?.indexedTags = Array(newTags).sorted()
        }
        .store(in: &cancellables)
    }

    // Watch for changes in selection and update audio player
    $detailSelection
      .sink { [weak self] newSelection in
        guard let self = self else { return }
        if let sample = self.matchToSample(id: newSelection) {
          self.slAudioPlayer.loadAudio(from: sample.fileURL)
          if self.slAudioPlayer.isAutoplay {
            self.slAudioPlayer.play()
          }
        }
      }
      .store(in: &cancellables)
				
				$indexedTags
						.receive(on: DispatchQueue.main)
						.map { tags in
								tags.map { tagString in
										SampleTagToken(id: UUID(), tag: tagString)
								}
						}
						.sink { [weak self] newTokens in
								self?.allTokens = newTokens
						}
						.store(in: &cancellables)

    // update music player slider as song plays
    slAudioPlayer.$currentTime
      .receive(on: DispatchQueue.main)
      .debounce(for: .milliseconds(20), scheduler: RunLoop.main)
      .sink { [weak self] newTime in
        self?.currentTime = newTime
      }
      .store(in: &cancellables)

  }

  private func matchToSample(id: UUID?) -> Sample? {
    // match uuid from detailSelection to its according sample object
    guard let id = id else { return nil }
    return samples.first { $0.id == id }
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
    ProxyRepresentation { fileRepresentable in fileRepresentable.file.fileURL }
  }
}
