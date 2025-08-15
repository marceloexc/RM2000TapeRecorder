import Combine
import CoreTransferable
import Foundation
import OSLog

struct SampleTagToken: Identifiable, Hashable {
  var id: UUID
  var tag: String
}

class SampleLibraryViewModel: ObservableObject {
  @Published var samples: [Sample] = []
  @Published var indexedTags: [String] = []
  @Published var finishedProcessing: Bool = false
  @Published var sidebarSelection: SampleFilterPredicate = .all
  @Published var predicateSelection = Set<UUID>()
  @Published var showInspector: Bool = false
  @Published var slAudioPlayer = SLAudioPlayer()
  @Published var currentTime: Double = 0
  @Published var searchText = ""
  @Published var currentSearchTokens = [SampleTagToken]()
  @Published var allTokens: [SampleTagToken] = []

  var selectedSamples: [FileRepresentable] {
    samples.filter( { self.predicateSelection.contains($0.id) } )
  }

  var suggestedSearchTokens: [SampleTagToken] {
    if searchText.isEmpty {
      return Array(allTokens)
    } else {
      return allTokens.filter { $0.tag.hasPrefix(searchText) }
    }
  }

  var filteredSamples: [Sample] {
    guard !searchText.isEmpty || !currentSearchTokens.isEmpty else {
      return samples
    }

    return samples.filter { sample in
      let textMatchCondition: Bool
      if searchText.isEmpty {
        textMatchCondition = true
      } else {
        textMatchCondition = sample.title.lowercased().contains(
          searchText.lowercased())
      }

      let tokenMatchCondition: Bool
      if currentSearchTokens.isEmpty {
        tokenMatchCondition = true
      } else {
        let selectedTokenTags = Set(currentSearchTokens.map { $0.tag })
        let sampleTags = Set(sample.tags)
        tokenMatchCondition = selectedTokenTags.isSubset(of: sampleTags)
      }

      return textMatchCondition && tokenMatchCondition
    }
  }

  private var sampleStorage: SampleStorage
  private var cancellables = Set<AnyCancellable>()

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
    $predicateSelection
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
  }

  private func matchToSample(id: Set<UUID>?) -> Sample? {
    guard id != nil else { return nil }
    return samples.first(where: { $0.id == id?.first })
  }
}

struct FileRepresentableItemModel: Identifiable, Hashable {
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

  static func == (lhs: FileRepresentableItemModel, rhs: FileRepresentableItemModel) -> Bool {
    return lhs.id == rhs.id
  }
}

// necessary extension for draggable objects in sample library window
extension FileRepresentableItemModel: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .fileURL) { fileRepresentable in
      // when dragging from app to finder
      Logger().debug(
        "SentTransferredFile from \(fileRepresentable.file.fileURL)")
      return SentTransferredFile(fileRepresentable.file.fileURL)
    }
    // without this, finder wont recognize our dropped item
    ProxyRepresentation { fileRepresentable in fileRepresentable.file.fileURL }
  }
}
