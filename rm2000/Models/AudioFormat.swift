//
//  AudioFormat.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/23/25.
//


enum AudioFormat: String, CaseIterable {
	case aac, mp3, flac, wav
	
	var asString: String {
		switch self {
		case .aac: return "aac"
		case .mp3: return "mp3"
		case .flac: return "flac"
		case .wav: return "wav"
		}
	}
	
	static func isSupported(extension ext: String) -> Bool {
		allCases.contains { $0.rawValue.lowercased() == ext.lowercased() }
	}
}
