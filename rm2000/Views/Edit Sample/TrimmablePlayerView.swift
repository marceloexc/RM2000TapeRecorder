// TrimmablePlayerView.swift
import SwiftUI
import AVKit
import AVFoundation
import Combine
import CoreMedia

class PlayerViewModel: ObservableObject {
	@Published var playerView: AVPlayerView?
	@Published var playerItem: AVPlayerItem? {
		didSet {
			setupAVPlayerObservations()
		}
	}
	var player: AVPlayer?
	var activeRecording: FileRepresentable
	
	private var cancellables = Set<AnyCancellable>()
	
	init(activeRecording: FileRepresentable) {
		self.activeRecording = activeRecording
		setupPlayer()
	}
	
	fileprivate func setupPlayer() {
		let fileURL = activeRecording.fileURL
		
		let asset = AVAsset(url: fileURL)
		let item = AVPlayerItem(asset: asset)
		self.playerItem = item
		
		player = AVPlayer(playerItem: playerItem)
		
		let view = AVPlayerView()
		view.player = player
		view.controlsStyle = .inline
		view.showsTimecodes = true
		view.showsSharingServiceButton = false
		view.showsFrameSteppingButtons = false
		view.showsFullScreenToggleButton = false
		
		playerView = view
	}
	
	private func setupAVPlayerObservations() {
		guard let playerItem = playerItem else { return }
		
		playerItem.publisher(for: \.status)
			.sink { [weak self] status in
				
				// .readytoplay in the AVPlayerItem.status enum
				if status == .readyToPlay {
					self?.objectWillChange.send()
				}
			}
			.store(in: &cancellables)
		
		playerItem.publisher(for: \.forwardPlaybackEndTime)
			.sink { [weak self] _ in
				self?.objectWillChange.send()
			}
			.store(in: &cancellables)
		
		playerItem.publisher(for: \.reversePlaybackEndTime)
			.sink { [weak self] _ in
				self?.objectWillChange.send()
			}
			.store(in: &cancellables)
	}
	
	func beginTrimming() {
		guard let playerView = playerView else { return }
		
		DispatchQueue.main.async {
			playerView.beginTrimming { result in
				switch result {
				case .okButton:
					print("Trim completed")
				case .cancelButton:
					print("Trim cancelled")
				@unknown default:
					print("Unknown trim result")
				}
			}
		}
	}
}

struct TrimmablePlayerView<Model: FileRepresentable>: View {
	@StateObject private var viewModel: PlayerViewModel
	// optional's as the CMTime's can be of NaN
	@Binding var forwardEndTime: CMTime?
	@Binding var reverseEndTime: CMTime?
	
	let model: Model
	
	init(recording: Model, forwardEndTime: Binding<CMTime?>, reverseEndTime: Binding<CMTime?>) {
		_viewModel = StateObject(wrappedValue: PlayerViewModel(activeRecording: recording))
		_forwardEndTime = forwardEndTime
		_reverseEndTime = reverseEndTime
		self.model = recording
	}
	
	var body: some View {
		VStack {
			if let playerView = viewModel.playerView {
				AudioPlayerView(playerView: playerView)
					.frame(height: 60)
			} else {
				Text("Player not available")
					.foregroundColor(.secondary)
			}
			if let playerItem = viewModel.playerItem {
				Text("forward time: \(playerItem.forwardPlaybackEndTime.seconds)")
				Text("reverse time: \(playerItem.reversePlaybackEndTime.seconds)")
			}
		}
	}
}

struct AudioPlayerView: NSViewRepresentable {
	let playerView: AVPlayerView
	
	func makeNSView(context: Context) -> AVPlayerView {
		Task {
			do {
				try await playerView.activateTrimming()
				playerView.hideTrimButtons()
			} catch {
				print("Failed to activate trimming: \(error)")
			}
		}
		return playerView
	}
	
	func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}
