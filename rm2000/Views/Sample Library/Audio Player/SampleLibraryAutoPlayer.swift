//
//  SampleLibraryAutoPlayer.swift
//  rm2000
//
//  Created by Marcelo Mendez on 5/4/25.
//
import SwiftUI
import AVFoundation
import Combine


class SLAudioPlayer: ObservableObject {
	private var player: AVPlayer?
	@Published var isPlaying = false
	@Published var currentTime: Double = 0
	@Published var duration: Double = 1
	@Published var isAutoplay: Bool = false
	
	private var timeObserver: Any?
	private var timer: AnyCancellable?
	
	init() {
		// nothing
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
		timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main) { [weak self] time in
			guard let self = self else { return }
			let currentSeconds = CMTimeGetSeconds(time)
			if currentSeconds.isFinite {
				self.currentTime = currentSeconds
				// Force object to update, which will refresh dependent views
//				self.objectWillChange.send()
			}
		}
		
		// Listen for when the item finishes playing
		NotificationCenter.default.addObserver(
			forName: .AVPlayerItemDidPlayToEndTime,
			object: player?.currentItem,
			queue: .main) { [weak self] _ in
				self?.isPlaying = false
				self?.player?.seek(to: CMTime.zero)
				self?.currentTime = 0
				self?.objectWillChange.send()
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
	
	func play() {
		if !isPlaying {
			player?.play()
			isPlaying = true
		}
	}
	
	func forcePause() {
		if isPlaying {
			player?.pause()
			isPlaying = false
		}
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
