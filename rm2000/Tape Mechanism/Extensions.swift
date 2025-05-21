//
//  Extensions.swift
//  rm2000
//
//  Created by Marcelo Mendez on 9/23/24.
//

import OSLog
import Foundation
import CoreMedia
import AVFAudio

extension Logger {
	static let tapeRecorder = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TapeRecorder")
	static let streamManager = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "StreamManager")
	static let audioManager = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AudioManager")
}
