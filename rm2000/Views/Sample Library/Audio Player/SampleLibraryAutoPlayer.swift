//
//  SampleLibraryAutoPlayer.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/4/25.
//
import SwiftUI
import AVFoundation

class SLAudioPlayer: ObservableObject {
	private var player: AVPlayer?
	@Published var isPlaying = false
	@Published var currentTime: Double = 0
	@Published var duration: Double = 1  // Default to 1 to avoid divide by zero
	
	private var timeObserver: Any?
	
	init() {
		// Initialize without a file initially
	}
	
	func loadAudio(from url: URL?) {
		// Clear any previous observer
		removeTimeObserver()
		
		// Reset state
		isPlaying = false
		currentTime = 0
		
		guard let url = url else { return }
		
		let playerItem = AVPlayerItem(url: url)
		player = AVPlayer(playerItem: playerItem)
		
		// Get duration
		if let duration = player?.currentItem?.asset.duration.seconds, !duration.isNaN {
			self.duration = duration
		}
		
		// Add time observer
		timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
			guard let self = self else { return }
			self.currentTime = time.seconds
		}
		
		// Listen for when the item finishes playing
		NotificationCenter.default.addObserver(
			forName: .AVPlayerItemDidPlayToEndTime,
			object: player?.currentItem,
			queue: .main) { [weak self] _ in
				self?.isPlaying = false
				self?.player?.seek(to: CMTime.zero)
			}
	}
	
	func playPause() {
		if isPlaying {
			player?.pause()
		} else {
			player?.play()
		}
		isPlaying.toggle()
	}
	
	func seekTo(time: Double) {
		player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
		currentTime = time
	}
	
	private func removeTimeObserver() {
		if let timeObserver = timeObserver {
			player?.removeTimeObserver(timeObserver)
			self.timeObserver = nil
		}
	}
	
	deinit {
		removeTimeObserver()
	}
}


struct SampleLibraryAutoPlayer: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SampleLibraryAutoPlayer()
}
