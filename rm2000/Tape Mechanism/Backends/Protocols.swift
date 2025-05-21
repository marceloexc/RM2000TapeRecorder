//
//  Protocols.swift
//  rm2000
//
//  Created by Marcelo Mendez on 9/23/24.
//

import Foundation
import CoreMedia
import ScreenCaptureKit

protocol StreamManagerDelegate: AnyObject {
	func streamManager(_ manager: SCStreamManager, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType)
	func streamManager(_ manager: SCStreamManager, didStopWithError error: Error)
}
